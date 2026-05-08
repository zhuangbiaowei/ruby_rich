#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/ruby_rich"

def assert(condition, message)
  raise "Assertion failed: #{message}" unless condition
end

editor = RubyRich::LineEditor.new(multiline: true)
editor.insert("hello 世界")
editor.move_left
editor.insert("🙂")
assert(editor.value == "hello 世🙂界", "unicode insertion respects cursor index")
editor.home
editor.insert(">")
editor.end
editor.insert("<")
assert(editor.value == ">hello 世🙂界<", "home/end move inside current line")
editor.kill_word_back
assert(editor.value == ">hello ", "ctrl+w style word deletion works")
editor.kill_to_start
assert(editor.value == "", "ctrl+u style line-start deletion works")
editor.kill_to_end
assert(editor.value == "", "ctrl+k at line end is stable")

editor.clear.insert("first\nsecond\nthird")
editor.buffer_start
editor.move_down
line, col = editor.cursor_line_col
assert(line == 1 && col == 0, "down moves within multiline input")
editor.end
editor.move_up
line, col = editor.cursor_line_col
assert(line == 0 && col == 5, "up preserves target column when possible")

single = RubyRich::LineEditor.new(multiline: false)
single.add_history("one")
single.add_history("two")
single.add_history("one")
assert(single.history == ["two", "one"], "history is deduplicated")
single.move_up
assert(single.value == "one", "up recalls history")
single.move_up
assert(single.value == "two", "repeated up continues through history after recall")
single.move_down
assert(single.value == "one", "down moves forward through recalled history")
single.insert("a\nb")
assert(single.value == "onea b", "single-line paste normalizes newlines")

submitted = []
selected = []
handled = []
interrupts = 0
eof = 0
pasted = nil
composer = RubyRich::Composer.new(
  commands: [
    { label: "help", value: "/help", description: "Help", handler: ->(args) { handled << ["/help", args] } },
    { label: "plan", value: "/plan", description: "Plan" }
  ],
  on_submit: ->(value, _live, attachments) { submitted << [value, attachments] },
  on_select: ->(command, _live) { selected << command[:value] },
  on_interrupt: -> { interrupts += 1 },
  on_eof: -> { eof += 1 },
  on_paste: ->(text, _composer) { pasted = text if text.is_a?(String) }
).focus
composer.width = 40
composer.height = 8

composer.handle_event({ type: :key, name: :string, value: "/" })
composer.handle_event({ type: :key, name: :tab })
composer.handle_event({ type: :key, name: :shift_tab })
assert(composer.menu_open?, "slash command menu opens and supports tab navigation")
composer.handle_event({ type: :key, name: :enter })
assert(composer.value.empty?, "enter submits the highlighted slash command")
assert(submitted.last.first == "/help", "enter submit includes the selected slash command")
assert(selected.last == "/help", "enter selection callback receives the highlighted slash command")
assert(handled.last == ["/help", ""], "enter selection runs the registered slash command handler")

escape_composer = RubyRich::Composer.new(commands: ["/help"]).focus
escape_composer.handle_event({ type: :key, name: :string, value: "/" })
assert(escape_composer.menu_open?, "slash command menu opens before escape")
escape_composer.handle_event({ type: :key, name: :escape })
assert(!escape_composer.menu_open?, "escape closes menu first")

filtered_submitted = []
filtered_handled = []
filtered_composer = RubyRich::Composer.new(
  commands: [{ label: "/help", value: "/help", handler: ->(args) { filtered_handled << args } }, "/plan"],
  on_submit: ->(value) { filtered_submitted << value }
).focus
filtered_composer.handle_event({ type: :key, name: :string, value: "/h" })
filtered_composer.handle_event({ type: :key, name: :enter })
assert(filtered_composer.value.empty?, "enter submits a filtered slash command")
assert(filtered_submitted.last == "/help", "filtered slash command submit uses the selected command")
assert(filtered_handled.last == "", "filtered slash command handler runs")

attachment = RubyRich::Attachment.new(type: :image, path: "image.png", mime_type: "image/png")
composer.add_attachment(attachment)
assert(composer.attachments.length == 1, "attachments can be added")
composer.remove_attachment(0)
assert(composer.attachments.empty?, "attachments can be removed")

composer.handle_event({ type: :key, name: :paste, value: "large\npaste\nblock" })
assert(pasted == "large\npaste\nblock", "paste is handled as one event")
composer.handle_event({ type: :key, name: :paste, value: "line1\r\nline2\rline3\n" })
assert(composer.value.include?("line1\nline2\nline3\n"), "pasted newlines stay in the editor instead of submitting")
composer.handle_event({ type: :key, name: :alt_enter })
composer.handle_event({ type: :key, name: :ctrl_enter })
composer.handle_event({ type: :key, name: :string, value: "tail" })
composer.handle_event({ type: :key, name: :enter }, nil)
assert(submitted.last.first.include?("large\npaste\nblock"), "enter submits multiline text")
assert(submitted.last.first.include?("\n\ntail"), "alt-enter and ctrl-enter insert newlines before submit")

composer.handle_event({ type: :key, name: :ctrl_c })
assert(interrupts == 1, "ctrl+c triggers interrupt")
composer.handle_event({ type: :key, name: :ctrl_d })
assert(eof == 1, "ctrl+d on empty input triggers eof")

lines = composer.render
assert(lines.all? { |line| line.gsub(/\e\[[0-9;:]*m/, "").display_width <= 40 }, "rendered lines fit composer width")

layout = RubyRich::Layout.new(name: :root)
layout.split_column(
  RubyRich::Layout.new(name: :log, ratio: 1),
  RubyRich::Layout.new(name: :composer, size: 3)
)
focus = RubyRich::FocusManager.new
composer_for_focus = RubyRich::Composer.new(commands: ["/help"]).focus
layout[:composer].content = composer_for_focus
focus
  .register(:log, layout[:log], Object.new)
  .register(:composer, layout[:composer], composer_for_focus)
  .attach(layout)
focus.focus(:log)
layout.notify_listeners(type: :key, name: :tab)
assert(focus.focused?(:composer), "tab moves focus into composer")
assert(composer_for_focus.value.empty?, "focus tab does not insert a slash")

menu_composer = RubyRich::Composer.new(commands: ["/help", "/plan"]).focus
menu_composer.width = 40
menu_composer.height = 3
menu_composer.handle_event({ type: :key, name: :string, value: "/" })
assert(menu_composer.desired_height >= 4, "slash menu desired height expands immediately")

puts "LineEditor and Composer checks passed"
