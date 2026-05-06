#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/ruby_rich'

puts 'Raw terminal event probe'
puts 'Click, right-click, wheel, or drag. Press q to exit.'
puts

RubyRich::Terminal.setup(mouse: true, hide_cursor: false)

begin
  loop do
    $stdin.raw(intr: true) do |io|
      RubyRich::Terminal.prepare_input
      char = io.getch
      bytes = char.b.bytes

      if char == 'q'
        puts 'exit'
        exit
      end

      if char == "\e"
        sequence = +''
        sleep 0.02
        while IO.select([io], nil, nil, 0)
          sequence << io.getch
          break if sequence.end_with?('M') || sequence.end_with?('m') || sequence.length >= 64
        end
        puts "ESC #{sequence.inspect} bytes=#{sequence.b.bytes.inspect}"
      else
        puts "#{char.inspect} bytes=#{bytes.inspect}"
      end
    end
  end
ensure
  RubyRich::Terminal.restore(mouse: true, show_cursor: true)
end
