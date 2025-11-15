module RubyRich
  class RichText
    # Default theme
    @@theme = {
      error: { color: :red, bold: true },
      success: { color: :green, bold: true },
      info: { color: :cyan },
      warning: { color: :yellow, bold: true }
    }

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
      "#{@styles.join}#{@text}#{AnsiCode.reset}"
    end

    private

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