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
    
    def print_with_pos(x,y,char)
      print "\e[#{y};#{x}H"   # Move cursor to top-left
      print char
    end
    
    def draw(buffer)
      unless @cache
        RubyRich::Terminal.clear
        draw_full(buffer)
        @cache = buffer
      else
        buffer.each_with_index do |arr, y|
          arr.each_with_index do |char, x|
            if @cache[y][x] != char
              print_with_pos(x + 1 , y + 1 , char)
              @cache[y][x] = char
            end
          end
        end
      end
    end

    private

    def draw_full(buffer)
      buffer.each_with_index do |line, y|
        print_with_pos(1, y + 1, line.compact.join(""))
      end
      $stdout.flush
    end
  end

  class Live
    attr_accessor :params, :app, :listening, :layout
    class << self
      def start(layout, refresh_rate: 30, mouse: false, alt_screen: false, autowrap: false, &proc)
        setup_terminal(mouse: mouse, alt_screen: alt_screen, autowrap: autowrap)
        live = new(layout, refresh_rate)
        live.mouse = mouse
        proc.call(live) if proc
        live.run(proc)
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
      @event_thread = nil
      @params = {}
      FileUtils.mkdir_p("./log")
      RubyRich.logger = Logger.new("./log/rich.log")
    end

    def run(proc = nil)
      start_event_thread if @listening
      while @running
        render_frame
        drain_event_queue if @listening
        sleep 1.0 / @refresh_rate
      end
    end

    def stop
      @running = false
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
            @event_queue << event_data if event_data
          rescue IOError, SystemCallError
            break
          rescue => e
            RubyRich.logger.error("Input event failed: #{e.class}: #{e.message}")
          end
        end
      end
    end

    def drain_event_queue
      until @event_queue.empty?
        event_data = @event_queue.pop(true)
        @layout.notify_listeners(event_data)
      end
    rescue ThreadError
      nil
    end

    def render_frame
      @layout.calculate_dimensions(terminal_width, terminal_height)
      @render.draw(@layout.render_to_buffer)
    end

    def terminal_width
      TTY::Screen.width
    end

    def terminal_height
      TTY::Screen.height
    end
  end
end
