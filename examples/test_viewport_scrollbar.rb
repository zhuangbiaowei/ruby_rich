#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/ruby_rich'

layout = RubyRich::Layout.new(name: :root)
layout.split_column(
  RubyRich::Layout.new(name: :viewport, ratio: 1),
  RubyRich::Layout.new(name: :status, size: 1)
)

lines = 200.times.map do |index|
  number = format('%03d', index + 1)
  "#{RubyRich::AnsiCode.color(:blue, true)}#{number}#{RubyRich::AnsiCode.reset}  #{'content ' * 16}"
end

viewport = RubyRich::Viewport.new(lines, scrollbar: true)
viewport.attach(layout[:viewport])
layout[:viewport].content = viewport

layout.key(:ctrl_c) { |_event, live| live.stop; false }
layout.key(:string) do |event, live|
  live.stop if event[:value] == 'q'
  false
end
layout.key(:escape) { |_event, live| live.stop; false }

layout[:status].content = Object.new.tap do |view|
  view.define_singleton_method(:render) do
    "scroll=#{viewport.scroll_top}/#{viewport.max_scroll_top} · wheel/PageUp/PageDown/Home/End · drag right scrollbar · q/Esc exits"
  end
end

RubyRich::Live.start(layout, refresh_rate: 20, mouse: true) do |live|
  live.listening = true
end
