#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/ruby_rich"

def assert(condition, message)
  raise "Assertion failed: #{message}" unless condition
end

called = nil
composer = RubyRich::Composer.new(commands: [])
composer.register_command(
  name: "/config",
  description: "Open configuration",
  aliases: ["/settings"],
  handler: ->(args) { called = args }
)
composer.focus
composer.handle_event({ type: :key, name: :string, value: "/config model=gpt" })
composer.handle_event({ type: :key, name: :enter })
assert(called == "model=gpt", "registered slash command receives args")

composer.handle_event({ type: :key, name: :string, value: "/set" })
composer.register_command(name: "/settings", hidden: true)
rendered = composer.render.join("\n")
assert(!rendered.include?("/settings"), "hidden commands are filtered from menu")

shell = RubyRich::AgentShell.new(title: "Runtime")
progress = shell.start_progress("Reading files")
assert(shell.progress_manager.current == progress, "progress manager exposes owned current handle")
progress.update("Calling model")
progress.finish("Done")
assert(!progress.update("Late update"), "finished progress handle cannot pollute UI")

nested = []
shell.with_progress("Outer") do |outer|
  nested << shell.progress_manager.current.message
  inner = shell.start_progress("Inner")
  nested << shell.progress_manager.current.message
  inner.finish
  nested << shell.progress_manager.current.message
  outer.finish
end
assert(nested == ["Outer", "Inner", "Outer"], "nested progress uses stack top as current display")

tool_id = shell.start_tool_call(name: "Read", input: { path: "lib/example.rb" }, status: :running)
shell.update_tool_call(tool_id, status: :done, output: "\e[32mok\e[0m")
tool_entry = shell.transcript.find_block(tool_id)
assert(tool_entry.status == :done, "tool call updates in place")
assert(shell.transcript.blocks.count { |entry| entry.id == tool_id } == 1, "tool updates do not duplicate entries")

markdown_id = shell.add_markdown("```ruby\nputs 'unterminated'\n", streaming: true)
shell.append_to_message(markdown_id, "```\n")
diff_id = shell.add_diff(title: "Patch", content: "+added\n-removed")
assert(shell.transcript.find_block(diff_id).type == :diff, "diff entries are supported")

assert(shell.confirm(title: "Allow tool?", message: "...", choices: [{ key: "n", label: "Deny" }], default: "n") == "n", "confirm returns default")
values = shell.form(title: "Configuration", fields: [
  { name: :api_key, type: :password },
  { name: :enabled, type: :boolean, default: true },
  { name: :models, type: :multi_select }
])
assert(values == { api_key: "", enabled: true, models: [] }, "form returns defaults by field type")

RubyRich::AnsiCode.color_enabled = false
assert(RubyRich::AnsiCode.color(:red) == "", "no-color mode disables ANSI")
RubyRich::AnsiCode.color_enabled = true

puts "Agent runtime API checks passed"
