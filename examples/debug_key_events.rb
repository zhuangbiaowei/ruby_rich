#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/ruby_rich"

console = RubyRich::Console.new
RubyRich::Terminal.debug_input = true

puts "RubyRich key event debug"
puts "Press keys to print parsed events. Press Ctrl+C to exit."
puts
begin
  RubyRich::Terminal.setup(mouse: true, hide_cursor: false, autowrap: true)

  loop do
    event = console.get_event
    next unless event

    RubyRich::Terminal.with_cooked(mouse: true) do
      puts event.inspect
    end

    break if event[:type] == :key && event[:name] == :ctrl_c
  end
rescue Interrupt
  nil
ensure
  RubyRich::Terminal.restore(mouse: true, show_cursor: true, autowrap: true)
end
