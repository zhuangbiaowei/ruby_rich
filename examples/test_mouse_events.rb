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
last_event_at = nil

layout.key(:ctrl_c) { |_event, live| live.stop; false }
layout.key(:string) do |event, live|
  live.stop if event[:value] == 'q'
  false
end

[:mouse_down, :mouse_up, :mouse_drag, :mouse_wheel].each do |name|
  layout.key(name) do |event, _live|
    label = "#{event[:name]} button=#{event[:button]} x=#{event[:raw_x]} y=#{event[:raw_y]}"
    label += " direction=#{event[:direction]}" if event[:direction]
    label += " modifiers=#{event[:modifiers].join('+')}" unless event[:modifiers].empty?
    events << label
    last_event_at = Time.now
    false
  end
end

layout[:body].content = Object.new.tap do |view|
  view.define_singleton_method(:render) do
    lines = [
      'Mouse event demo',
      'Click, right-click, wheel, or drag inside the terminal.',
      'Press q or Ctrl+C to exit.',
      '',
      'Recent events:',
      *events.last(18)
    ]
    panel = RubyRich::Panel.new(lines.join("\n"), title: 'Mouse Events', border_style: :blue, title_align: :left)
    panel.width = layout[:body].width
    panel.height = layout[:body].height
    panel.render
  end
end

layout[:status].content = Object.new.tap do |view|
  view.define_singleton_method(:render) do
    elapsed = (Time.now - started_at).round(1)
    last = last_event_at ? "#{(Time.now - last_event_at).round(1)}s ago" : "never"
    "mouse events=#{events.size} · uptime=#{elapsed}s · last=#{last}"
  end
end

RubyRich::Live.start(layout, refresh_rate: 20, mouse: true) do |live|
  live.listening = true
end
