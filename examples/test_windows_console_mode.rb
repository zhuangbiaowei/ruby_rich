#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/ruby_rich'

def print_mode(label)
  mode = RubyRich::Terminal.windows_input_mode
  if mode
    puts "#{label}: 0x#{mode.to_s(16)}"
    puts "  ENABLE_MOUSE_INPUT=#{(mode & RubyRich::Terminal::ENABLE_MOUSE_INPUT) != 0}"
    puts "  ENABLE_QUICK_EDIT_MODE=#{(mode & RubyRich::Terminal::ENABLE_QUICK_EDIT_MODE) != 0}"
    puts "  ENABLE_EXTENDED_FLAGS=#{(mode & RubyRich::Terminal::ENABLE_EXTENDED_FLAGS) != 0}"
    puts "  ENABLE_VIRTUAL_TERMINAL_INPUT=#{(mode & RubyRich::Terminal::ENABLE_VIRTUAL_TERMINAL_INPUT) != 0}"
  else
    puts "#{label}: not a Windows console handle"
  end
end

print_mode('before')
RubyRich::Terminal.setup(mouse: true, hide_cursor: false)
print_mode('after setup')

$stdin.raw(intr: true) do
  print_mode('inside raw before prepare')
  RubyRich::Terminal.prepare_input
  print_mode('inside raw after prepare')
end

RubyRich::Terminal.restore(mouse: true, show_cursor: true)
print_mode('after restore')
