#!/usr/bin/env ruby
# frozen_string_literal: true

require "fiddle"
require_relative "../lib/ruby_rich"

def assert(condition, message)
  raise "Assertion failed: #{message}" unless condition
end

def key_record(virtual_key:, char_code: 0, control_state: 0, key_down: true)
  record = Fiddle::Pointer.malloc(RubyRich::Terminal::INPUT_RECORD_SIZE)
  record[0, 2] = [RubyRich::Terminal::KEY_EVENT].pack("S")
  record[4, 4] = [key_down ? 1 : 0].pack("L")
  record[10, 2] = [virtual_key].pack("S")
  record[12, 4] = [control_state].pack("L")
  record[14, 2] = [char_code].pack("S")
  record
end

terminal = RubyRich::Terminal

{
  ctrl_a: 1,
  ctrl_e: 5,
  ctrl_k: 11,
  ctrl_u: 21,
  ctrl_w: 23
}.each do |name, code|
  event = terminal.send(:parse_windows_input_record, key_record(virtual_key: code + 64, char_code: code))
  assert(event[:name] == name, "Windows #{name} key record is parsed")
end

enter_with_unreliable_shift_bit = terminal.send(
  :parse_windows_input_record,
  key_record(virtual_key: 13, char_code: 13, control_state: RubyRich::Terminal::SHIFT_PRESSED)
)
assert(enter_with_unreliable_shift_bit[:name] == :enter, "Windows Enter ignores unreliable Shift bit when char is CR")

ctrl_enter_lf = terminal.send(
  :parse_windows_input_record,
  key_record(virtual_key: 13, char_code: 10, control_state: RubyRich::Terminal::LEFT_CTRL_PRESSED)
)
assert(ctrl_enter_lf[:name] == :ctrl_enter, "Windows Ctrl+Enter LF key record is not mistaken for Shift+Enter")

shift_enter_lf = terminal.send(
  :parse_windows_input_record,
  key_record(virtual_key: 13, char_code: 10)
)
assert(shift_enter_lf[:name] == :shift_enter, "Windows LF Enter key record inserts a newline")

shift_enter_lf = terminal.send(
  :parse_windows_input_record,
  key_record(virtual_key: 13, char_code: 10, control_state: RubyRich::Terminal::SHIFT_PRESSED)
)
assert(shift_enter_lf[:name] == :shift_enter, "Windows Shift+Enter LF with shift key record is parsed")

alt_enter = terminal.send(
  :parse_windows_input_record,
  key_record(virtual_key: 13, control_state: RubyRich::Terminal::LEFT_ALT_PRESSED)
)
assert(alt_enter[:name] == :alt_enter, "Windows Alt+Enter key record is parsed")

shift_tab = terminal.send(
  :parse_windows_input_record,
  key_record(virtual_key: 9, control_state: RubyRich::Terminal::SHIFT_PRESSED)
)
assert(shift_tab[:name] == :shift_tab, "Windows Shift+Tab key record is parsed")

backspace = terminal.send(:parse_windows_input_record, key_record(virtual_key: 8, char_code: 8))
assert(backspace[:name] == :backspace, "Windows Backspace key record is not mistaken for Ctrl+H")

terminal.instance_variable_set(:@windows_pending_events, [])
enter = RubyRich::Event.key(:enter)
event = terminal.send(:finish_windows_coalesced_events, [enter, enter], enter)
pending = terminal.send(:next_windows_pending_event)
assert(event == enter, "short Windows Enter burst is returned as one submit event")
assert(pending.nil?, "short Windows Enter burst does not queue a duplicate submit")

terminal.instance_variable_set(:@windows_pending_events, [])
first_ime_char = RubyRich::Event.key(:string, value: "你")
second_ime_char = RubyRich::Event.key(:string, value: "好")
event = terminal.send(:finish_windows_coalesced_events, [first_ime_char, second_ime_char], first_ime_char)
pending = terminal.send(:next_windows_pending_event)
assert(event == first_ime_char, "short Windows text burst is returned as the first character")
assert(pending == second_ime_char, "short Windows text burst preserves later IME characters")

paste = terminal.send(
  :finish_windows_coalesced_events,
  [RubyRich::Event.key(:string, value: "a"), RubyRich::Event.key(:enter), RubyRich::Event.key(:string, value: "b")],
  RubyRich::Event.key(:string, value: "a")
)
assert(paste[:name] == :paste && paste[:value] == "a\nb", "Windows string-enter-string burst is treated as paste")

puts "Windows key record checks passed"
