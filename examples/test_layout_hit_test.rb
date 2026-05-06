#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/ruby_rich'

layout = RubyRich::Layout.new(name: :root)
layout.split_row(
  RubyRich::Layout.new(name: :left, ratio: 1),
  RubyRich::Layout.new(name: :right, ratio: 1)
)

last_hit = "none"
clicks = []

layout.key(:ctrl_c) { |_event, live| live.stop; false }
layout.key(:string) do |event, live|
  live.stop if event[:value] == 'q'
  false
end

[:left, :right].each do |name|
  layout[name].key(:mouse_down) do |event, _live|
    last_hit = name.to_s
    clicks << "#{name} x=#{event[:raw_x]} y=#{event[:raw_y]} button=#{event[:button]}"
    true
  end
end

layout[:left].content = Object.new.tap do |view|
  view.define_singleton_method(:render) do
    panel = RubyRich::Panel.new(
      "Click inside this panel.\n\nLast hit: #{last_hit}\n\n#{clicks.last(8).join("\n")}",
      title: 'Left',
      border_style: last_hit == 'left' ? :green : :blue,
      title_align: :left
    )
    panel.width = layout[:left].width
    panel.height = layout[:left].height
    panel.render
  end
end

layout[:right].content = Object.new.tap do |view|
  view.define_singleton_method(:render) do
    panel = RubyRich::Panel.new(
      "Click inside this panel.\n\nLast hit: #{last_hit}\n\n#{clicks.last(8).join("\n")}",
      title: 'Right',
      border_style: last_hit == 'right' ? :green : :blue,
      title_align: :left
    )
    panel.width = layout[:right].width
    panel.height = layout[:right].height
    panel.render
  end
end

RubyRich::Live.start(layout, refresh_rate: 20, mouse: true) do |live|
  live.listening = true
end
