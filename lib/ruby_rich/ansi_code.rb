module RubyRich
  class AnsiCode
    ANSI_CODES = {
      reset: "\e[0m",
      bold: "1",
      faint: "2",
      italic: "3",
      underline: "4",
      curly_underline: "4:3",
      dotted_underline: "4:4",
      dashed_underline: "4:5",
      double_underline: "21",
      blink: "5",
      rapid_blink: "6",
      inverse: "7",
      invisible: "8",
      strikethrough: "9",
      fraktur: "20",
      no_blink: "25",
      no_inverse: "27",
      overline: "53",
      color: {
        black: "30",
        red: "31",
        green: "32",
        yellow: "33",
        blue: "34",
        magenta: "35",
        cyan: "36",
        white: "37"
      },
      bright_color:{
        black: "90",
        red: "91",
        green: "92",
        yellow: "93",
        blue: "94",
        magenta: "95",
        cyan: "96",
        white: "97"
      },
      background: {
        black: "40",
        red: "41",
        green: "42",
        yellow: "43",
        blue: "44",
        magenta: "45",
        cyan: "46",
        white: "47"
      },
      bright_background: {
        black: "100",
        red: "101",
        green: "102",
        yellow: "103",
        blue: "104",
        magenta: "105",
        cyan: "106",
        white: "107"
      }
    }

    def self.reset
      return "" unless color_enabled?

      ANSI_CODES[:reset]
    end

    def self.color(color, bright=false)
      return "" unless color_enabled?

      if bright
        "\e[#{ANSI_CODES[:bright_color][color]}m"
      else
        "\e[#{ANSI_CODES[:color][color]}m"
      end
    end

    def self.background(color, bright=false)
      return "" unless color_enabled?

      if bright
        "\e[#{ANSI_CODES[:bright_background][color]}m"
      else
        "\e[#{ANSI_CODES[:background][color]}m"
      end
    end

    def self.bold
      return "" unless color_enabled?

      "\e[#{ANSI_CODES[:bold]}m"
    end

    def self.faint
      return "" unless color_enabled?

      "\e[#{ANSI_CODES[:faint]}m"
    end

    def self.italic
      return "" unless color_enabled?

      "\e[#{ANSI_CODES[:italic]}m"
    end

    def self.underline(style=nil)
      return "" unless color_enabled?

      case style
      when nil
        return "\e[#{ANSI_CODES[:underline]}m"
      when :double
        return "\e[#{ANSI_CODES[:double_underline]}m"
      when :curly
        return "\e[#{ANSI_CODES[:curly_underline]}m"
      when :dotted
        return "\e[#{ANSI_CODES[:dotted_underline]}m"
      when :dashed
        return "\e[#{ANSI_CODES[:dashed_underline]}m"  
      end
    end

    def self.blink
      return "" unless color_enabled?

      "\e[#{ANSI_CODES[:blink]}m"
    end

    def self.rapid_blink
      return "" unless color_enabled?

      "\e[#{ANSI_CODES[:rapid_blink]}m"
    end

    def self.inverse
      return "" unless color_enabled?

      "\e[#{ANSI_CODES[:inverse]}m"
    end

    def self.fraktur
      return "" unless color_enabled?

      "\e[#{ANSI_CODES[:fraktur]}m"
    end

    def self.invisible
      return "" unless color_enabled?

      "\e[#{ANSI_CODES[:invisible]}m"
    end

    def self.strikethrough
      return "" unless color_enabled?

      "\e[#{ANSI_CODES[:strikethrough]}m"
    end
    
    def self.overline
      return "" unless color_enabled?

      "\e[#{ANSI_CODES[:overline]}m"
    end

    def self.no_blink
      return "" unless color_enabled?

      "\e[#{ANSI_CODES[:no_blink]}m"
    end

    def self.no_inverse
      return "" unless color_enabled?

      "\e[#{ANSI_CODES[:no_inverse]}m"
    end

    def self.font(font_color, 
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
      return "" unless color_enabled?

      code = if font_bright
        "\e[#{ANSI_CODES[:bright_color][font_color]}"
      else
        "\e[#{ANSI_CODES[:color][font_color]}"
      end
      if background
        code += ";" + if background_bright
          "#{ANSI_CODES[:bright_background][background]}"
        else
          "#{ANSI_CODES[:background][background]}"
        end
      end
      if bold
        code += ";" + ANSI_CODES[:bold]
      end
      if italic
        code += ";" + ANSI_CODES[:italic]
      end
      if underline
        case underline_style
        when nil
          code += ";" + ANSI_CODES[:underline]
        when :double
          code += ";" + ANSI_CODES[:double_underline]
        when :curly
          code += ";" + ANSI_CODES[:curly_underline]
        when :dotted
          code += ";" + ANSI_CODES[:dotted_underline]
        when :dashed
          code += ";" + ANSI_CODES[:dashed_underline]
        end
      end
      if strikethrough
        code += ";" +  ANSI_CODES[:strikethrough]
      end
      if overline
        code += ";" +  ANSI_CODES[:overline]
      end
      return code+"m"
    end

    def self.color_enabled?
      ENV["NO_COLOR"].nil? && ENV["TERM"] != "dumb" && @color_enabled != false
    end

    def self.color_enabled=(enabled)
      @color_enabled = enabled
    end
  end
end
