module RubyRich
  class RichText
    # 默认主题
    @@theme = {
      error: { color: :red, bold: true },
      success: { color: :green, bold: true },
      info: { color: :cyan },
      warning: { color: :yellow, bold: true }
    }

    # Rich markup 标记映射
    MARKUP_PATTERNS = {
      # Basic colors
      /\[red\](.*?)\[\/red\]/m => proc { |text| "\e[31m#{text}\e[0m" },
      /\[green\](.*?)\[\/green\]/m => proc { |text| "\e[32m#{text}\e[0m" },
      /\[yellow\](.*?)\[\/yellow\]/m => proc { |text| "\e[33m#{text}\e[0m" },
      /\[blue\](.*?)\[\/blue\]/m => proc { |text| "\e[34m#{text}\e[0m" },
      /\[magenta\](.*?)\[\/magenta\]/m => proc { |text| "\e[35m#{text}\e[0m" },
      /\[cyan\](.*?)\[\/cyan\]/m => proc { |text| "\e[36m#{text}\e[0m" },
      /\[white\](.*?)\[\/white\]/m => proc { |text| "\e[37m#{text}\e[0m" },
      /\[black\](.*?)\[\/black\]/m => proc { |text| "\e[30m#{text}\e[0m" },
      
      # Bright colors
      /\[bright_red\](.*?)\[\/bright_red\]/m => proc { |text| "\e[91m#{text}\e[0m" },
      /\[bright_green\](.*?)\[\/bright_green\]/m => proc { |text| "\e[92m#{text}\e[0m" },
      /\[bright_yellow\](.*?)\[\/bright_yellow\]/m => proc { |text| "\e[93m#{text}\e[0m" },
      /\[bright_blue\](.*?)\[\/bright_blue\]/m => proc { |text| "\e[94m#{text}\e[0m" },
      /\[bright_magenta\](.*?)\[\/bright_magenta\]/m => proc { |text| "\e[95m#{text}\e[0m" },
      /\[bright_cyan\](.*?)\[\/bright_cyan\]/m => proc { |text| "\e[96m#{text}\e[0m" },
      /\[bright_white\](.*?)\[\/bright_white\]/m => proc { |text| "\e[97m#{text}\e[0m" },
      
      # Text styles
      /\[bold\](.*?)\[\/bold\]/m => proc { |text| "\e[1m#{text}\e[22m" },
      /\[dim\](.*?)\[\/dim\]/m => proc { |text| "\e[2m#{text}\e[22m" },
      /\[italic\](.*?)\[\/italic\]/m => proc { |text| "\e[3m#{text}\e[23m" },
      /\[underline\](.*?)\[\/underline\]/m => proc { |text| "\e[4m#{text}\e[24m" },
      /\[blink\](.*?)\[\/blink\]/m => proc { |text| "\e[5m#{text}\e[25m" },
      /\[reverse\](.*?)\[\/reverse\]/m => proc { |text| "\e[7m#{text}\e[27m" },
      /\[strikethrough\](.*?)\[\/strikethrough\]/m => proc { |text| "\e[9m#{text}\e[29m" },
      
      # Combined styles
      /\[bold\s+(\w+)\](.*?)\[\/bold\s+\1\]/m => proc do |text, color_match|
        color_code = color_to_ansi(color_match)
        "\e[1m#{color_code}#{text}\e[0m"
      end
    }.freeze

    def self.set_theme(new_theme)
      @@theme.merge!(new_theme)
    end

    def initialize(text, style: nil)
      @text = text
      @styles = []
      apply_theme(style) if style
    end

    def style(color: :white, 
      font_bright: false, 
      background: nil, 
      background_bright: false,
      bold: false, 
      italic: false,
      underline: false,
      underline_style: nil,
      strikethrough: false,
      overline: false
      )
      @styles << AnsiCode.font(color, font_bright, background, background_bright, bold, italic, underline, underline_style, strikethrough, overline)
      self
    end

    def render
      processed_text = process_markup(@text)
      "#{@styles.join}#{processed_text}#{AnsiCode.reset}"
    end

    # 处理 Rich markup 标记语言
    def self.markup(text)
      new(text).render_markup
    end

    def render_markup
      process_markup(@text)
    end

    private

    def process_markup(text)
      result = text.dup
      
      # 处理组合样式 (如 [bold red])
      result.gsub!(/\[(\w+)\s+(\w+)\](.*?)\[\/\1\s+\2\]/m) do |match|
        style1, style2, content = $1, $2, $3
        
        # 确定哪个是样式，哪个是颜色
        if is_color?(style2)
          apply_combined_style(content, style1, style2)
        elsif is_color?(style1)
          apply_combined_style(content, style2, style1)
        else
          match # 无法处理的组合，返回原文
        end
      end
      
      # 处理基本样式和颜色
      MARKUP_PATTERNS.each do |pattern, processor|
        result.gsub!(pattern) do |match|
          if pattern.source.include?('\\s+')
            # 这是组合样式，已经在上面处理过了
            match
          else
            processor.call($1)
          end
        end
      end
      
      result
    end

    def apply_combined_style(content, style, color)
      color_code = color_to_ansi(color)
      style_code = style_to_ansi(style)
      "#{style_code}#{color_code}#{content}\e[0m"
    end

    def is_color?(word)
      %w[red green yellow blue magenta cyan white black bright_red bright_green bright_yellow bright_blue bright_magenta bright_cyan bright_white].include?(word)
    end

    def color_to_ansi(color)
      color_map = {
        'red' => "\e[31m", 'green' => "\e[32m", 'yellow' => "\e[33m",
        'blue' => "\e[34m", 'magenta' => "\e[35m", 'cyan' => "\e[36m",
        'white' => "\e[37m", 'black' => "\e[30m",
        'bright_red' => "\e[91m", 'bright_green' => "\e[92m", 'bright_yellow' => "\e[93m",
        'bright_blue' => "\e[94m", 'bright_magenta' => "\e[95m", 'bright_cyan' => "\e[96m",
        'bright_white' => "\e[97m"
      }
      color_map[color] || ""
    end

    def style_to_ansi(style)
      style_map = {
        'bold' => "\e[1m", 'dim' => "\e[2m", 'italic' => "\e[3m",
        'underline' => "\e[4m", 'blink' => "\e[5m", 'reverse' => "\e[7m",
        'strikethrough' => "\e[9m"
      }
      style_map[style] || ""
    end

    def add_style(code, error_message)
      if code
        @styles << code
      else
        raise ArgumentError, error_message
      end
    end

    def apply_theme(style)
      theme_styles = @@theme[style]
      raise ArgumentError, "Undefined theme style: #{style}" unless theme_styles
      style(**theme_styles)
    end
  end
end