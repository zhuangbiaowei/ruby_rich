require 'io/console'
require_relative 'event'
require_relative 'terminal'

module RubyRich
  class Console
    ESCAPE_SEQUENCES = {
      # 方向键
      '[A' => :up,    '[B' => :down,
      '[C' => :right, '[D' => :left,
      # 功能键
      'OP' => :f1, 'OQ' => :f2, 'OR' => :f3, 'OS' => :f4,
      '[15~' => :f5, '[17~' => :f6, '[18~' => :f7,
      '[19~' => :f8, '[20~' => :f9, '[21~' => :f10,
      '[23~' => :f11, '[24~' => :f12,
      # 添加媒体键示例
      '[1~' => :home,    '[4~' => :end,
      # 添加 macOS 功能键
      '[25~' => :audio_mute,
      # 其他
      '[5~' => :page_up, '[6~' => :page_down,
      '[H' => :home, '[F' => :end,
      '[2~' => :insert, '[3~' => :delete,
      '[Z' => :shift_tab,
      '[13;2u' => :shift_enter,
      '[13;3u' => :alt_enter,
      '[13;2~' => :shift_enter,
      '[13;3~' => :alt_enter
    }.freeze

    WINDOWS_SPECIAL_KEYS = {
      72 => :up,
      80 => :down,
      75 => :left,
      77 => :right,
      71 => :home,
      79 => :end,
      73 => :page_up,
      81 => :page_down,
      82 => :insert,
      83 => :delete
    }.freeze

    def initialize
      @lines = []
      @buffer = []
      @layout = { spacing: 1, align: :left }
      @styles = {}
    end

    def set_layout(spacing: 1, align: :left)
      @layout[:spacing] = spacing
      @layout[:align] = align
    end

    def style(name, **attributes)
      @styles[name] = attributes
    end

    def print(*objects, sep: ' ', end_char: "\n", immediate: false)
      line_text = objects.map do |obj|
        if obj.is_a?(String) && obj.include?('[')
          # 处理 Rich markup 标记
          RichText.markup(obj)
        else
          obj.to_s
        end
      end.join(sep)
      
      if immediate
        add_line(line_text)
        render
      else
        # 简单输出，不使用 Console 的缓冲和渲染系统
        Kernel.puts line_text
      end
    end

    def log(message, *objects, sep: ' ', end_char: "\n")
      timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      log_message = "[#{timestamp}] LOG: #{message} #{objects.map(&:to_s).join(sep)}"
      add_line(log_message)
      render
    end

    def rule(title: nil, characters: '#', style: 'bold')
      rule_line = characters * 80
      if title
        formatted_title = " #{title} ".center(80, characters)
        add_line(formatted_title)
      else
        add_line(rule_line)
      end
      render
    end

    def self.raw
      old_state = `stty -g`
      system('stty raw -echo -icanon isig') rescue nil
      yield
    ensure
      system("stty #{old_state}") rescue nil
    end

    def self.clear
      system('clear')
    end

    def get_event(input: $stdin)
      if RubyRich::Terminal.windows_mouse_reporting?
        event = RubyRich::Terminal.read_windows_input_event
        return event if event
      end

      get_key(input: input)
    end

    def get_key(input: $stdin)
      input.raw(intr: true) do |io|
        RubyRich::Terminal.prepare_input
        char = io.getch
        bytes = char.b.bytes
        byte = bytes.first

        return Event.key(:ctrl_c) if byte == 3

        # Handle Enter key first (ASCII 13 = \r, ASCII 10 = \n)
        if char == "\r" || char == "\n"
          # Check for subsequent input (pasted content has multiple characters)
          has_more = IO.select([io], nil, nil, 0)

          return has_more ? Event.key(:paste, value: collect_pending_input(io, char)) : Event.key(:enter)
        end
        # Handle Tab key separately (ASCII 9)
        if char == "\t"
          return Event.key(:tab)
        elsif byte == 8 || byte == 0x7F
          return Event.key(:backspace)
        # Windows special keys can be delivered as:
        # - "\xE0" + a second getch byte
        # - "\xE0H" in one read
        elsif byte == 0 || byte == 224
          code = bytes[1]
          code ||= io.getch.b.bytes.first
          return Event.key(WINDOWS_SPECIAL_KEYS[code] || :"windows_special_#{code}")
        elsif char == "\e" # Detect escape sequence
          sequence = char.b.bytes.drop(1).pack('C*')

          sleep 0.01
          while IO.select([io], nil, nil, 0)
            next_char = io.getch
            break unless next_char

            sequence << next_char
            return read_bracketed_paste(io) if sequence == "[200~"
            break if complete_escape_sequence?(sequence)
          end

          if sequence.empty?
            return Event.key(:escape)
          elsif sequence == "\r" || sequence == "\n"
            return Event.key(:alt_enter)
          elsif (mouse_event = parse_sgr_mouse(sequence))
            return mouse_event
          else
            return Event.key(ESCAPE_SEQUENCES[sequence] || :"ansi_#{sequence.inspect}")
          end
        # Handle Ctrl combinations (excluding Tab and Enter)
        elsif byte.between?(1, 8) || byte.between?(10, 26)
          ctrl_char = (byte + 64).chr.downcase
          return Event.key("ctrl_#{ctrl_char}".to_sym)
        else
          if IO.select([io], nil, nil, 0)
            Event.key(:paste, value: collect_pending_input(io, char))
          else
            Event.key(:string, value: char)
          end
        end
      end
    end

    def parse_sgr_mouse(sequence)
      match = sequence.match(/\A\[<(\d+);(\d+);(\d+)([Mm])\z/)
      return nil unless match

      code = match[1].to_i
      raw_x = match[2].to_i
      raw_y = match[3].to_i
      terminator = match[4]
      button = mouse_button(code)
      name = mouse_event_name(code, terminator)
      direction = mouse_wheel_direction(code)

      Event.mouse(
        name,
        button: button,
        x: raw_x - 1,
        y: raw_y - 1,
        raw_x: raw_x,
        raw_y: raw_y,
        code: code,
        modifiers: mouse_modifiers(code),
        direction: direction
      )
    end

    def add_line(text)
      @lines << text
    end

    def clear
      Kernel.print "\e[H\e[2J"
    end

    def render
      clear
      @lines.each_with_index do |line, index|
        formatted_line = format_line(line)
        @buffer << formatted_line
        Kernel.puts formatted_line
        Kernel.puts "\n" * @layout[:spacing] if index < @lines.size - 1
      end
    end

    def update_line(index, text)
      return unless index.between?(0, @lines.size - 1)
      @lines[index] = text
      render
    end

    private

    def read_bracketed_paste(io)
      terminator = "\e[201~"
      buffer = +""
      loop do
        char = io.getch
        break unless char

        buffer << char
        break if buffer.end_with?(terminator)
      end
      buffer = normalize_paste_text(buffer.delete_suffix(terminator))
      Event.key(:paste, value: buffer)
    end

    def collect_pending_input(io, first_char)
      buffer = +first_char
      while IO.select([io], nil, nil, 0)
        char = io.getch
        break unless char

        buffer << char
      end
      normalize_paste_text(buffer)
    end

    def normalize_paste_text(text)
      text.to_s.gsub(/\r\n?/, "\n")
    end

    def complete_escape_sequence?(sequence)
      if sequence.start_with?('[<')
        sequence.end_with?('M') || sequence.end_with?('m') || sequence.length >= 32
      else
        ESCAPE_SEQUENCES.key?(sequence) || sequence.length >= 8
      end
    end

    def mouse_event_name(code, terminator)
      return :mouse_up if terminator == 'm'
      return :mouse_wheel if (code & 64) == 64
      return :mouse_drag if (code & 32) == 32

      :mouse_down
    end

    def mouse_button(code)
      return :wheel if (code & 64) == 64

      case code & 3
      when 0 then :left
      when 1 then :middle
      when 2 then :right
      else :unknown
      end
    end

    def mouse_wheel_direction(code)
      return nil unless (code & 64) == 64

      (code & 1) == 1 ? :down : :up
    end

    def mouse_modifiers(code)
      modifiers = []
      modifiers << :shift if (code & 4) == 4
      modifiers << :alt if (code & 8) == 8
      modifiers << :ctrl if (code & 16) == 16
      modifiers
    end

    def format_line(line)
      content = line.is_a?(RichText) ? line.render : line
      case @layout[:align]
      when :center
        content.center(80)
      when :right
        content.rjust(80)
      else
        content
      end
    end
  end
end
