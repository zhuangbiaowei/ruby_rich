module RubyRich
  class Console
    def initialize
      @lines = []
      @buffer = []
      @layout = { spacing: 1, align: :left }
    end

    def set_layout(spacing: 1, align: :left)
      @layout[:spacing] = spacing
      @layout[:align] = align
    end

    def add_line(text)
      @lines << text
    end

    def clear
      print "\e[H\e[2J"
    end

    def render
      clear
      @lines.each_with_index do |line, index|
        formatted_line = format_line(line)
        @buffer << formatted_line
        puts formatted_line
        puts "\n" * @layout[:spacing] if index < @lines.size - 1
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
