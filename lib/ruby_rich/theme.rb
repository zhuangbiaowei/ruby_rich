# frozen_string_literal: true

module RubyRich
  class Theme
    DEFAULT_ROLES = {
      accent: { color: :blue, bright: true, bold: true },
      body: { color: :white, bright: true },
      muted: { color: :black, bright: true },
      dim: { color: :black, bright: true },
      thinking: { color: :white, bright: true, italic: true },
      success: { color: :green, bright: true },
      warning: { color: :yellow, bright: true },
      error: { color: :red, bright: true },
      status: { color: :cyan, bright: true }
    }.freeze

    attr_reader :roles, :border, :focused_border

    def self.agent_dark
      new(
        border: :blue,
        focused_border: :cyan,
        roles: {
          accent: { color: :blue, bright: true, bold: true },
          body: { color: :white, bright: true },
          muted: { color: :black, bright: true },
          dim: { color: :black, bright: true },
          thinking: { color: :white, bright: true, italic: true },
          success: { color: :green, bright: true },
          warning: { color: :yellow, bright: true },
          error: { color: :red, bright: true },
          status: { color: :cyan, bright: true }
        }
      )
    end

    def initialize(roles: {}, border: :blue, focused_border: :cyan)
      @roles = DEFAULT_ROLES.merge(roles)
      @border = border
      @focused_border = focused_border
    end

    def style(text, role = :body)
      options = @roles.fetch(role, @roles[:body])
      "#{style_code(options)}#{text}#{AnsiCode.reset}"
    end

    def color(name, bright: false)
      AnsiCode.color(name, bright)
    end

    def panel_border(focused: false)
      focused ? @focused_border : @border
    end

    private

    def style_code(options)
      code = AnsiCode.font(
        options.fetch(:color, :white),
        font_bright: options.fetch(:bright, false),
        bold: options[:bold],
        italic: options[:italic]
      )
      code += AnsiCode.faint if options[:faint]
      code
    end
  end
end
