#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/ruby_rich"

def assert(condition, message)
  raise "Assertion failed: #{message}" unless condition
end

layout = RubyRich::Layout.new(name: :root)
viewport = RubyRich::Viewport.new("alpha\nbeta 中文\ncharlie", scrollbar: true)
viewport.width = 20
viewport.height = 3
layout.content = viewport
layout.calculate_dimensions(20, 3)
viewport.attach(layout)

layout.notify_listeners(type: :mouse, name: :mouse_down, x: 0, y: 1)
layout.notify_listeners(type: :mouse, name: :mouse_drag, x: 6, y: 1)
layout.notify_listeners(type: :mouse, name: :mouse_up, x: 6, y: 1)
assert(viewport.selected_text == "beta 中", "mouse selection is constrained to viewport text")

layout.notify_listeners(type: :mouse, name: :mouse_down, x: 1, y: 0)
layout.notify_listeners(type: :mouse, name: :mouse_drag, x: 4, y: 2)
rendered = viewport.render.join("\n")
assert(rendered.include?(RubyRich::AnsiCode.inverse), "active selection is highlighted")
layout.notify_listeners(type: :mouse, name: :mouse_up, x: 4, y: 2)
assert(layout.notify_listeners(type: :mouse, name: :mouse_down, button: :right, x: 1, y: 0), "right click copies existing viewport selection")

puts "Viewport selection checks passed"
