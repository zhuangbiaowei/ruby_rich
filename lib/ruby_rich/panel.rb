module RubyRich
  class Panel
    attr_accessor :width, :height, :content, :line_pos, :border_style, :title
    COLORS = {
      red: "\e[31m",
      green: "\e[32m",
      blue: "\e[34m",
      yellow: "\e[33m",
      cyan: "\e[36m",
      white: "\e[37m",
      reset: "\e[0m"
    }

    def initialize(content = "", title: nil, border_style: :white)
      @content = content
      @title = title
      @border_style = border_style
      @width = 0
      @height = 0
      @line_pos = 0
    end

    def inner_width
      @width - 2  # Account for border characters
    end

    def calculate_string_width(str)
      width = 0
      str.each_char do |char|
        width += Unicode::DisplayWidth.of(char)
      end
      width
    end

    def render
      lines = []
      color_code = COLORS[@border_style] || COLORS[:white]
      reset_code = COLORS[:reset]

      # Top border
      top_border = color_code + "┌"
      if @title
        title_text = "[ #{@title} ]"        
        top_border += title_text + '─' * (@width - calculate_string_width(@title)-6)
      else
        top_border += '─' * (@width - 2)
      end
      top_border += "┐" + reset_code
      lines << top_border

      # Content area
      content_lines = wrap_content(@content)
      if content_lines.size > @height - 2
        @line_pos = content_lines.size - @height + 2
        content_lines=content_lines[@line_pos..-1]
      end
      content_lines.each do |line|
        lines << color_code + "│" + reset_code +
                line + " "*(@width - calculate_string_width(line) - 2) +
                color_code + "│" + reset_code
      end

      # Fill remaining vertical space
      remaining_lines = @height - 2 - content_lines.size
      remaining_lines.times do
        lines << color_code + "│" + reset_code +
                " " * (@width - 2) +
                color_code + "│" + reset_code
      end

      # Bottom border
      lines << color_code + "└" + "─" * (@width - 2) + "┘" + reset_code

      lines
    end

    def update_content(new_content)
      @content = new_content
    end

    private

    def split_text_by_width(text)
      result = []
      current_line = ""
      current_width = 0
    
      text.each_char do |char|
        char_width = Unicode::DisplayWidth.of(char)
        if current_width + char_width <= @width - 4
          current_line += char
          current_width += char_width
        else
          result << current_line
          current_line = char
          current_width = char_width
        end
      end
    
      # 添加最后一行
      result << current_line unless current_line.empty?
    
      result
    end

    def wrap_content(text)
      text.split("\n").flat_map do |line|
        split_text_by_width(line)
      end
    end
  end
end
module RubyRich
    class RichPanel
        # ANSI escape codes for styling
        ANSI_CODES = {
          reset: "\e[0m",
          bold: "\e[1m",
          underline: "\e[4m",
          color: {
            black: "\e[30m",
            red: "\e[31m",
            green: "\e[32m",
            yellow: "\e[33m",
            blue: "\e[34m",
            magenta: "\e[35m",
            cyan: "\e[36m",
            white: "\e[37m"
          },
          background: {
            black: "\e[40m",
            red: "\e[41m",
            green: "\e[42m",
            yellow: "\e[43m",
            blue: "\e[44m",
            magenta: "\e[45m",
            cyan: "\e[46m",
            white: "\e[47m"
          }
        }
      
        attr_accessor :title, :content, :border_color, :title_color, :footer
      
        def initialize(content, title: nil, footer: nil, border_color: :white, title_color: :white)
          @content = content.is_a?(String) ? content.split("\n") : content
          @title = title
          @footer = footer
          @border_color = border_color
          @title_color = title_color
        end
      
        def render
          content_lines = format_content
          panel_width = calculate_panel_width(content_lines)
      
          lines = []
          lines << top_border(panel_width)
          lines += content_lines.map { |line| format_line(line, panel_width) }
          lines << bottom_border(panel_width)
      
          lines.join("\n")
        end
      
        private
      
        def top_border(width)
          title_text = @title ? colorize(" #{@title} ", @title_color) : ""
          padding = (width - title_text.uncolorize.length - 2) / 2
          "#{colorize("╭", @border_color)}#{colorize("─" * padding, @border_color)}#{title_text}#{colorize("─" * (width - title_text.uncolorize.length - padding - 2), @border_color)}#{colorize("╮", @border_color)}"
        end
      
        def bottom_border(width)
          footer_text = @footer ? colorize(" #{@footer} ", @title_color) : ""
          padding = (width - footer_text.uncolorize.length - 2) / 2
          "#{colorize("╰", @border_color)}#{colorize("─" * padding, @border_color)}#{footer_text}#{colorize("─" * (width - footer_text.uncolorize.length - padding - 2), @border_color)}#{colorize("╯", @border_color)}"
        end
      
        def format_line(line, width)
          "#{colorize("│", @border_color)} #{line.ljust(width - 4)} #{colorize("│", @border_color)}"
        end
      
        def format_content
          @content.map(&:strip)
        end
      
        def calculate_panel_width(content_lines)
          [
            @title ? @title.uncolorize.length + 4 : 0,
            @footer ? @footer.uncolorize.length + 4 : 0,
            content_lines.map(&:length).max + 4
          ].max
        end
      
        def colorize(text, color)
          code = ANSI_CODES[:color][color] || ""
          "#{code}#{text}#{ANSI_CODES[:reset]}"
        end
      end
end

# Extend String to remove ANSI codes for alignment
class String
    def uncolorize
        gsub(/\e\[[0-9;]*m/, '')
    end
end
