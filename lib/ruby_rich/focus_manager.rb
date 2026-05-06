# frozen_string_literal: true

module RubyRich
  class FocusManager
    attr_reader :focused_name

    def initialize
      @entries = []
      @focused_name = nil
    end

    def register(name, layout, target)
      @entries << { name: name, layout: layout, target: target }
      focus(name) unless @focused_name
      self
    end

    def attach(root_layout, priority: 500)
      root_layout.key(:tab, priority) do |_event_data, _live|
        focus_next
        false
      end

      root_layout.key(:mouse_down, priority) do |event_data, _live|
        entry = entry_at(event_data[:x], event_data[:y])
        if entry
          focus(entry[:name])
          false
        else
          false
        end
      end

      self
    end

    def focus(name)
      entry = @entries.find { |item| item[:name] == name }
      return nil unless entry

      blur_current
      @focused_name = entry[:name]
      entry[:target].focus if entry[:target].respond_to?(:focus)
      entry
    end

    def focus_next
      return nil if @entries.empty?

      index = @entries.index { |entry| entry[:name] == @focused_name } || -1
      focus(@entries[(index + 1) % @entries.length][:name])
    end

    def focused?(name)
      @focused_name == name
    end

    private

    def blur_current
      current = @entries.find { |entry| entry[:name] == @focused_name }
      current[:target].blur if current && current[:target].respond_to?(:blur)
    end

    def entry_at(x, y)
      @entries.reverse.find { |entry| entry[:layout].contains?(x, y) }
    end
  end
end
