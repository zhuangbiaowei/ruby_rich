#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/ruby_rich'

unless RubyRich::Terminal.windows?
  warn 'This probe is only useful on Windows.'
  exit 1
end

puts 'Windows Console Input Record probe'
puts 'Click, right-click, wheel, or drag. Press q to exit.'
puts

RubyRich::Terminal.setup(mouse: true, hide_cursor: false)

begin
  loop do
    event = RubyRich::Terminal.read_windows_input_event
    next unless event

    p event
    break if event[:name] == :string && event[:value] == 'q'
    break if event[:name] == :ctrl_c
  end
ensure
  RubyRich::Terminal.restore(mouse: true, show_cursor: true)
end
