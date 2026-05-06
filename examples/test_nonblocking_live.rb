#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/ruby_rich'

layout = RubyRich::Layout.new(name: :root)
layout.split_column(
  RubyRich::Layout.new(name: :body, ratio: 1),
  RubyRich::Layout.new(name: :status, size: 1)
)

events = []
started_at = Time.now

layout.key(:ctrl_c) { |_event, live| live.stop; false }
layout.key(:string) do |event, live|
  events << "string: #{event[:value].inspect}"
  live.stop if event[:value] == 'q'
  false
end
[:up, :down, :left, :right, :enter, :escape, :tab].each do |name|
  layout.key(name) do |_event, live|
    events << "key: #{name}"
    live.stop if name == :escape
    false
  end
end

layout[:body].content = Object.new.tap do |view|
  view.define_singleton_method(:render) do
    elapsed = (Time.now - started_at).round(1)
    lines = [
      "Non-blocking Live demo",
      "Elapsed: #{elapsed}s",
      "Press keys while the timer keeps moving. Press q or Esc to exit.",
      "",
      "Recent events:",
      *events.last(12)
    ]
    panel = RubyRich::Panel.new(lines.join("\n"), title: 'Event Loop', border_style: :cyan, title_align: :left)
    panel.width = layout[:body].width
    panel.height = layout[:body].height
    panel.render
  end
end

layout[:status].content = Object.new.tap do |view|
  view.define_singleton_method(:render) do
    "events=#{events.size} · running"
  end
end

RubyRich::Live.start(layout, refresh_rate: 20) do |live|
  live.listening = true
end
