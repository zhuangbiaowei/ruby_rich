module RubyRich
  class RichText
    # 默认主题
    @@theme = {
      error: { color: :red, bold: true },
      success: { color: :green, bold: true },
      info: { color: :cyan },
      warning: { color: :yellow, bold: true }
    }

    # ANSI 转义码常量
    ANSI_CODES = {
      reset: "\e[0m",
      bold: "\e[1m",
      italic: "\e[3m",
      underline: "\e[4m",
      blink: "\e[5m",
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

    def self.set_theme(new_theme)
      @@theme.merge!(new_theme)
    end

    def initialize(text, style: nil)
      @text = text
      @styles = []
      apply_theme(style) if style
    end

    def style(color: nil, background: nil, bold: false, italic: false, underline: false, blink: false)
      @styles << ANSI_CODES[:color][color] if color
      @styles << ANSI_CODES[:background][background] if background
      @styles << ANSI_CODES[:bold] if bold
      @styles << ANSI_CODES[:italic] if italic
      @styles << ANSI_CODES[:underline] if underline
      @styles << ANSI_CODES[:blink] if blink
      self
    end

    def render
      "#{@styles.join}#{@text}#{ANSI_CODES[:reset]}"
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