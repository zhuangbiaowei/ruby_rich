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
