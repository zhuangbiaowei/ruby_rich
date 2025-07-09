require 'io/console'

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
      '[2~' => :insert, '[3~' => :delete
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

    def get_key(input: $stdin)
      input.raw(intr: true) do |io|
        char = io.getch
        # 优先处理回车键（ASCII 13 = \r，ASCII 10 = \n）
        if char == "\r" || char == "\n"
          # 检查是否有后续输入（粘贴内容会有多个字符）
          has_more = IO.select([io], nil, nil, 0)
          return has_more ? {:name => :string, :value => char} : {:name=>:enter}
        end
        # 单独处理 Tab 键（ASCII 9）
        if char == "\t"
          return {:name=>:tab}
        elsif char.ord == 0x07F
          return {:name=>:backspace}
        elsif char == "\e" # 检测到转义序列
          sequence = ''
          begin
            while (c = io.read_nonblock(1))
              sequence << c
            end
          rescue IO::WaitReadable
            retry if IO.select([io], nil, nil, 0.01)
          rescue EOFError
          end
          if sequence.empty?
            return {:name => :escape}
          else
            return {:name => ESCAPE_SEQUENCES[sequence]} || {:name => :escape}
          end
        # 处理 Ctrl 组合键（排除 Tab 和回车）
        elsif char.ord.between?(1, 8) || char.ord.between?(10, 26)
          ctrl_char = (char.ord + 64).chr.downcase
          return {:name =>"ctrl_#{ctrl_char}".to_sym}
        else
          {:name => :string, :value => char}
        end
      end
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