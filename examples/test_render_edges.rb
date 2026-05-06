#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/ruby_rich'

layout = RubyRich::Layout.new(name: :root)

started_at = Time.now
tick = 0

layout.key(:ctrl_c) { |_event, live| live.stop; false }
layout.key(:string) do |event, live|
  live.stop if event[:value] == 'q'
  false
end
layout.key(:escape) { |_event, live| live.stop; false }

layout.content = Object.new.tap do |view|
  view.define_singleton_method(:render) do
    width = layout.width
    height = layout.height
    tick += 1

    lines = Array.new(height) { ' ' * width }
    top = "#{RubyRich::AnsiCode.color(:blue, true)}#{'─' * width}#{RubyRich::AnsiCode.reset}"
    bottom = top
    lines[0] = top if height.positive?
    lines[-1] = bottom if height > 1

    if width > 1 && height > 2
      (1...(height - 1)).each do |y|
        left = RubyRich::AnsiCode.color(:blue, true) + '│' + RubyRich::AnsiCode.reset
        right = RubyRich::AnsiCode.color(:blue, true) + '│' + RubyRich::AnsiCode.reset
        body = ' ' * [width - 2, 0].max
        lines[y] = "#{left}#{body}#{right}"
      end
    end

    message = "Render edge probe · #{width}x#{height} · #{(Time.now - started_at).round(1)}s · press q/Esc"
    marker_y = height > 4 ? 2 + (tick / 4) % (height - 4) : 1
    if marker_y < lines.length
      available = [width - 4, 1].max
      visible_message = message[0, available]
      lines[marker_y] = "#{RubyRich::AnsiCode.color(:blue, true)}│#{RubyRich::AnsiCode.reset} #{visible_message}#{' ' * [available - visible_message.length, 0].max} #{RubyRich::AnsiCode.color(:blue, true)}│#{RubyRich::AnsiCode.reset}"
    end

    lines
  end
end

RubyRich::Live.start(layout, refresh_rate: 12, alt_screen: true) do |live|
  live.listening = true
end
