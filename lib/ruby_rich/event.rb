# frozen_string_literal: true

module RubyRich
  module Event
    module_function

    def key(name, value: nil)
      event = { name: name, type: :key }
      event[:value] = value unless value.nil?
      event
    end

    def mouse(name, button:, x:, y:, raw_x:, raw_y:, code:, modifiers: [], direction: nil)
      event = {
        name: name,
        type: :mouse,
        button: button,
        x: x,
        y: y,
        raw_x: raw_x,
        raw_y: raw_y,
        code: code,
        modifiers: modifiers
      }
      event[:direction] = direction if direction
      event
    end
  end
end
