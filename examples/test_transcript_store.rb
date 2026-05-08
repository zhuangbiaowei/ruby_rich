#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/ruby_rich"

def assert(condition, message)
  raise "Assertion failed: #{message}" unless condition
end

store = RubyRich::Transcript::Store.new

assistant = store.add(type: :assistant, content: "", metadata: { streaming: true })
store.append(assistant.id, "hello")
store.append(assistant.id, " world")
assert(assistant.content == "hello world", "assistant content streams through append")

tool = store.add(type: :tool, content: "input: README.md", status: :running, name: "read_file")
store.update(tool.id) { |entry| entry.status = :done }
assert(tool.status == :done, "tool status updates to done")
store.update(tool.id) { |entry| entry.status = :error }
assert(tool.status == :error, "tool status updates to error")
store.update(tool.id) { |entry| entry.status = :cancelled }
assert(tool.status == :cancelled, "tool status updates to cancelled")

thinking = store.add(type: :thinking, content: "private reasoning")
assert(thinking.collapsed, "thinking starts collapsed by default")
store.expand(thinking.id)
assert(thinking.collapsed == false, "thinking expands through API")
store.collapse(thinking.id)
assert(thinking.collapsed == true, "thinking collapses through API")

markdown = store.add(type: :markdown, content: "# Title\n\nbody")
first_render = markdown.cache_fetch([:markdown, 80]) { [:rendered_once] }
second_render = markdown.cache_fetch([:markdown, 80]) { [:rendered_twice] }
assert(first_render.equal?(second_render), "markdown render cache is reused while content is unchanged")
store.append(markdown.id, "\nmore")
third_render = markdown.cache_fetch([:markdown, 80]) { [:rendered_after_change] }
assert(third_render == [:rendered_after_change], "markdown render cache invalidates after content changes")

transcript = RubyRich::Transcript.new(store: store)
transcript.width = 81
user_id = transcript.add_user("line one\nline two\nline three")
rendered_user = transcript.render
assert(rendered_user.any? { |line| line.include?("line two") }, "user messages preserve submitted newlines")
assert(rendered_user.any? { |line| line.include?("line three") }, "user messages render each submitted line")
wide_transcript = RubyRich::Transcript.new
wide_transcript.width = 60
wide_transcript.add_user("验收标准：OpenClacky 工具线程和模型流式线程不会争用 UI 内部状态。")
first_wide_line = wide_transcript.render.first.gsub(/\e\[[0-9;:]*m/, "")
assert(first_wide_line.display_width > 30, "ANSI prefixes do not force narrow message wrapping")
viewport_transcript = RubyRich::Transcript.new
viewport_transcript.add_user("验收标准：OpenClacky 工具线程和模型流式线程不会争用 UI 内部状态。")
viewport = RubyRich::Viewport.new(viewport_transcript, scrollbar: true)
viewport.width = 60
viewport.height = 5
first_viewport_line = viewport.render.first.gsub(/\e\[[0-9;:]*m/, "")
assert(first_viewport_line.display_width > 30, "viewport passes its content width into transcript rendering")
transcript.width = 82

render_calls = 0
class << RubyRich::Markdown
  alias_method :render_without_store_test, :render
end
RubyRich::Markdown.define_singleton_method(:render) do |text, options = {}|
  render_calls += 1
  render_without_store_test(text, options)
end

begin
  2.times { transcript.render }
  assert(render_calls == 1, "transcript reuses cached markdown across refreshes")
ensure
  class << RubyRich::Markdown
    alias_method :render, :render_without_store_test
    remove_method :render_without_store_test
  end
end

tool.collapsed = true
transcript.handle_event(type: :key, name: :ctrl_o)
assert(tool.collapsed == false, "Ctrl+O expands the next collapsible entry")

store.remove(assistant.id)
assert(store.find(assistant.id).nil?, "entries can be removed")

puts "Transcript store checks passed"
