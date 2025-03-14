module RubyRich
  class Panel
    attr_accessor :width, :height, :content, :line_pos, :border_style, :title
    attr_accessor :title_align, :content_changed

    def initialize(content = "", title: nil, border_style: :white, title_align: :center)
      @content = content
      @title = title
      @border_style = border_style
      @width = 0
      @height = 0
      @line_pos = 0
      @title_align = title_align
    end

    def inner_width
      @width - 2  # Account for border characters
    end

    def page_up
      @line_pos -= ( @height - 4 )
      if @line_pos < 0
        @line_pos = 0
      end
      @content_changed = false
    end

    def page_down
      unless @content.empty?
        content_lines = wrap_content(@content)
        @line_pos += ( @height - 4 )
        if @line_pos + ( @height - 4 ) > content_lines.size
          @line_pos = content_lines.size - @height + 2
        end
        @content_changed = false
      end      
    end

    def home
      @line_pos = 0
      @content_changed = false
    end

    def end
      unless @content.empty?
        content_lines = wrap_content(@content)
        @line_pos = content_lines.size - @height + 2
        @content_changed = false
      end
    end

    def render
      lines = []
      color_code = AnsiCode.color(@border_style) || AnsiCode.color(:white)
      reset_code = AnsiCode.reset

      # Top border
      top_border = color_code + "┌"
      if @title
        title_text = "[ #{@title} ]"
        bar_width = @width - @title.display_width-6
        case @title_align
        when :left
          top_border += title_text + '─' * bar_width
        when :center
          top_border += '─' * (bar_width/2)  + title_text + '─' * (bar_width - bar_width/2)
        when :right
          top_border += '─' * bar_width + title_text
        end
      else
        top_border += '─' * (@width - 2)
      end
      top_border += "┐" + reset_code
      lines << top_border

      # Content area
      content_lines = wrap_content(@content)
      if @line_pos==0
        if @content_changed == false
          if content_lines.size > @height - 2
            content_lines=content_lines[0..@height - 3]
          end
        else
          if content_lines.size > @height - 2
            @line_pos = content_lines.size - @height + 2
            content_lines=content_lines[@line_pos..-1]
            @content_changed = false
          end
        end
      else
        if @line_pos+@height-2 >= content_lines.size
          content_lines=content_lines[@line_pos..-1]
        else
          content_lines=content_lines[@line_pos..@line_pos+@height-3]
        end
      end
      
      content_lines.each do |line|
        lines << color_code + "│" + reset_code +
                line + " "*(@width - line.display_width - 2) +
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

    def content=(new_content)
      @content = new_content
      content_lines = wrap_content(@content)
      if content_lines.size > @height - 2
        @line_pos = content_lines.size - @height + 2
      end
      @content_changed = true
    end

    private

    def split_text_by_width(text)
      result = []
      current_line = ""
      current_width = 0
      
      # Split text into tokens of ANSI codes and regular text
      tokens = text.scan(/(\e\[[0-9;]*m)|(.)/)
                   .map { |m| m.compact.first }
      start_color = nil
      tokens.each do |token|
        # Calculate width for regular text, ANSI codes have 0 width
        if token.start_with?("\e[")
          if token == "\e[0m"
            start_color = nil
          else
            start_color = token
          end
          token_width = 0
        else
          token_width = token.chars.sum { |c| Unicode::DisplayWidth.of(c) }
        end
      
        if current_width + token_width <= @width - 4
          current_line += token
          current_width += token_width
        else
          result << current_line
          current_line = start_color.to_s+token
          current_width = token_width
        end
      end
      
      # Add remaining line
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

# Extend String to remove ANSI codes for alignment
class String
    def uncolorize
        gsub(/\e\[[0-9;]*m/, '')
    end

    def display_width
      width = 0
      self.uncolorize.each_char do |char|
        width += Unicode::DisplayWidth.of(char)
      end
      width
    end
end
