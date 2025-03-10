require 'io/console'
require "tty-screen"
require "tty-cursor"

module RubyRich

  class CacheRender
    def initialize
      @cache = nil
    end
    
    def print_with_pos(x,y,char)
      print "\e[?25l"   # 隐藏光标
      print "\e[#{y};#{x}H"   # 移动光标到左上角
      print char
    end
    
    def draw(buffer)
      unless @cache
        system("clear")
        print_with_pos(0,0,buffer.map { |line| line.compact.join("") }.join("\n"))
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
  end

  class Live
    attr_accessor :params, :app, :listening, :layout
    class << self
      def start(layout, refresh_rate: 30, &proc)
        setup_terminal
        live = new(layout, refresh_rate)
        proc.call(live) if proc
        live.run(proc)
      rescue => e
        puts e.message
      ensure
        restore_terminal
      end

      private

      def setup_terminal
        @original_state = `stty -g`
        system("stty -echo")
      end

      def restore_terminal
        system("stty #{@original_state}")
        print TTY::Cursor.show
      end
    end

    def initialize(layout, refresh_rate)
      @layout = layout
      @layout.live = self
      @refresh_rate = refresh_rate
      @running = true
      @last_frame = Time.now
      @cursor = TTY::Cursor
      @render = CacheRender.new
      @console = RubyRich::Console.new
      @params = {}
    end

    def run(proc = nil)
      while @running
        render_frame
        if @listening
          event_data = @console.get_key()
          @layout.notify_listeners(event_data)
        end
        sleep 1.0 / @refresh_rate
      end
    end

    def stop
      @running = false
      system("clear")
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