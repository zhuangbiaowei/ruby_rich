require 'io/console'
require 'fileutils'
require "tty-screen"
require "tty-cursor"
require "thread"
require_relative "terminal"

module RubyRich

  class CacheRender
    def initialize
      @cache = nil
    end
    
    def print_with_pos(x,y,text)
      print "\e[#{y};#{x}H"   # Move cursor to top-left
      print text
    end
    
    def draw(buffer)
      unless @cache
        RubyRich::Terminal.clear
        draw_full(buffer)
        @cache = buffer
      else
        draw_changes(buffer)
      end
    end

    private

    def draw_changes(buffer)
      buffer.each_with_index do |line, y|
        cache_line = @cache[y] ||= []
        x = 0
        while x < line.length
          if cache_line[x] == line[x]
            x += 1
            next
          end

          start = x
          parts = []
          while x < line.length && cache_line[x] != line[x]
            char = line[x]
            parts << char unless char.nil?
            cache_line[x] = char
            x += 1
          end

          print_with_pos(start + 1, y + 1, parts.join) unless parts.empty?
        end
      end
      $stdout.flush
    end

    def draw_full(buffer)
      buffer.each_with_index do |line, y|
        print_with_pos(1, y + 1, line.compact.join(""))
      end
      $stdout.flush
    end
  end

  class Live
    RESIZE_POLL_INTERVAL = 0.25

    attr_accessor :params, :app, :listening, :layout
    class << self
      def start(layout, refresh_rate: 30, mouse: false, alt_screen: false, autowrap: false, &proc)
        setup_terminal(mouse: mouse, alt_screen: alt_screen, autowrap: autowrap)
        live = new(layout, refresh_rate)
        live.mouse = mouse
        proc.call(live) if proc
        live.run(proc)
      rescue Interrupt
        live&.stop
      rescue => e
        puts e.message
      ensure
        live&.shutdown
        restore_terminal(mouse: mouse, alt_screen: alt_screen)
      end

      private

      def setup_terminal(mouse: false, alt_screen: false, autowrap: false)
        RubyRich::Terminal.setup(mouse: mouse, alt_screen: alt_screen, autowrap: autowrap)
      end

      def restore_terminal(mouse: false, alt_screen: false)
        RubyRich::Terminal.restore(mouse: mouse, alt_screen: alt_screen, autowrap: true)
      end
    end

    attr_accessor :mouse

    def initialize(layout, refresh_rate)
      @layout = layout
      @layout.live = self
      @refresh_rate = refresh_rate
      @running = true
      @last_frame = Time.now
      @cursor = TTY::Cursor
      @render = CacheRender.new
      @console = RubyRich::Console.new
      @event_queue = Queue.new
      @action_queue = Queue.new
      @event_thread = nil
      @wake_mutex = Mutex.new
      @wake_condition = ConditionVariable.new
      @dirty = true
      @last_terminal_size = nil
      @params = {}
      if (log_path = ENV["RUBY_RICH_LOG"]).to_s.strip != ""
        FileUtils.mkdir_p(File.dirname(log_path))
        RubyRich.logger = Logger.new(log_path)
      end
    end

    def run(proc = nil)
      start_event_thread if @listening
      while @running
        action_processed = drain_action_queue
        break unless @running

        event_processed = @listening ? drain_event_queue : false
        if consume_dirty || action_processed || event_processed || terminal_size_changed?
          render_frame
        else
          wait_for_activity
        end
      end
    rescue Interrupt
      @running = false
    end

    def post(&block)
      return false unless block
      return false unless @running

      @action_queue << block
      wake
      true
    end

    def refresh
      return false unless @running

      mark_dirty
      wake
      true
    end

    def stop
      @running = false
      wake
      shutdown
      RubyRich::Terminal.clear
    end

    def shutdown
      if @event_thread&.alive?
        @event_thread.kill
        @event_thread = nil
      end
    end

    def move_cursor(x,y)
      print @cursor.move_to(x, y)
    end

    def find_layout(name)
      @layout[name]
    end

    def find_panel(name)
      @layout[name].content
    end

    private

    def start_event_thread
      return if @event_thread&.alive?

      @event_thread = Thread.new do
        while @running
          begin
            event_data = @console.get_event
            if event_data
              @event_queue << event_data
              wake
            end
          rescue IOError, SystemCallError
            break
          rescue Interrupt
            @running = false
            break
          rescue => e
            RubyRich.logger.error("Input event failed: #{e.class}: #{e.message}")
          end
        end
      end
    end

    def drain_event_queue
      processed = false
      until @event_queue.empty?
        event_data = @event_queue.pop(true)
        @layout.notify_listeners(event_data)
        processed = true
      end
      processed
    rescue ThreadError
      processed
    end

    def drain_action_queue
      processed = false
      until @action_queue.empty?
        action = @action_queue.pop(true)
        action.call(self)
        processed = true
      end
      processed
    rescue ThreadError
      processed
    rescue => e
      RubyRich.logger.error("UI action failed: #{e.class}: #{e.message}")
      true
    end

    def render_frame
      width = terminal_width
      height = terminal_height
      @last_terminal_size = [width, height]
      @layout.calculate_dimensions(width, height)
      @render.draw(@layout.render_to_buffer)
      position_native_cursor
    end

    def position_native_cursor
      composer_layout = @layout[:composer]
      return unless composer_layout

      frame = composer_layout.content
      component = frame.instance_variable_get(:@component) if frame
      return unless component&.respond_to?(:native_cursor_position)

      cursor = component.native_cursor_position
      return unless cursor

      row, col = cursor
      terminal_row = composer_layout.y_offset.to_i + 1 + row.to_i
      terminal_col = composer_layout.x_offset.to_i + 1 + col.to_i
      print "\e[#{terminal_row + 1};#{terminal_col + 1}H"
      $stdout.flush
    end

    def wait_for_activity
      @wake_mutex.synchronize do
        return unless @running
        return unless @action_queue.empty?
        return if @listening && !@event_queue.empty?

        @wake_condition.wait(@wake_mutex, RESIZE_POLL_INTERVAL)
      end
    end

    def wake
      @wake_mutex.synchronize { @wake_condition.signal }
    end

    def mark_dirty
      @wake_mutex.synchronize { @dirty = true }
    end

    def consume_dirty
      @wake_mutex.synchronize do
        dirty = @dirty
        @dirty = false
        dirty
      end
    end

    def terminal_size_changed?
      current_size = [terminal_width, terminal_height]
      changed = @last_terminal_size != current_size
      @last_terminal_size = current_size
      changed
    end

    def terminal_width
      TTY::Screen.width
    end

    def terminal_height
      TTY::Screen.height
    end
  end
end
