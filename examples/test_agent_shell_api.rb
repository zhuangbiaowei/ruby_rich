#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/ruby_rich"

class FakeLive
  attr_reader :actions

  def initialize
    @actions = Queue.new
    @running = true
  end

  def post(&block)
    return false unless @running

    @actions << block
    true
  end

  def drain
    @actions.pop(true).call(self) until @actions.empty?
  rescue ThreadError
    nil
  end

  def stop
    @running = false
  end

  def running?
    @running
  end
end

def assert(condition, message)
  raise "Assertion failed: #{message}" unless condition
end

shell = RubyRich::AgentShell.new(title: "OpenClacky")
submitted_shell = RubyRich::AgentShell.new(title: "Submit")
submitted_shell.on_submit { |text, _attachments| submitted_shell.add_user_message(text) }
submitted_shell.send(:handle_submit, "multi\nline", nil, [])
assert(submitted_shell.transcript.blocks.count { |entry| entry.type == :user } == 1, "AgentShell submit does not duplicate user messages")

quit_live = FakeLive.new
submitted_shell.send(:handle_submit, "/quit", quit_live, [])
assert(!quit_live.running?, "AgentShell /quit stops the live loop")

interrupt_live = FakeLive.new
submitted_shell.send(:handle_interrupt, interrupt_live, submitted_shell)
assert(!interrupt_live.running?, "AgentShell Ctrl+C exits when composer input is empty")

submitted_shell.composer.editor.insert("draft")
interrupt_live_with_input = FakeLive.new
submitted_shell.send(:handle_interrupt, interrupt_live_with_input, submitted_shell)
assert(!interrupt_live_with_input.running?, "AgentShell Ctrl+C exits even when composer input is not empty")

user_id = shell.add_user_message("hello")
assistant_id = shell.add_assistant_message("", streaming: true)
assert(user_id.start_with?("user-"), "user messages return stable ids")
assert(assistant_id.start_with?("assistant-"), "assistant messages return stable ids")

assert(shell.append_to_message(assistant_id, "world"), "append succeeds")
assert(shell.replace_message(assistant_id, "replacement"), "replace succeeds")
assert(shell.remove_entry(user_id), "remove succeeds")
assert(shell.transcript.find_block(user_id).nil?, "remove deletes the entry")
assert(shell.transcript.find_block(assistant_id)[:text] == "replacement", "replace updates text")

tool_id = shell.start_tool_call(name: "read_file", input: "README.md", status: :running)
assert(tool_id.start_with?("tool-"), "tool calls return stable ids")
assert(shell.finish_tool_call(tool_id, status: :done, output: "ok"), "tool finish succeeds")
assert(shell.transcript.find_block(tool_id)[:status] == :done, "tool status updates")

fake_live = FakeLive.new
starting_id = nil
shell.instance_variable_get(:@state_mutex).synchronize do
  shell.instance_variable_set(:@state, :starting)
  shell.instance_variable_set(:@live, nil)
end
starting_worker = Thread.new { starting_id = shell.add_assistant_message("starting") }
starting_worker.join
assert(shell.transcript.find_block(starting_id).nil?, "startup-window API call is queued")
shell.send(:drain_pending_actions, fake_live)
assert(shell.transcript.find_block(starting_id)[:text] == "starting", "startup-window API call drains on UI runtime")

shell.instance_variable_get(:@state_mutex).synchronize do
  shell.instance_variable_set(:@state, :running)
  shell.instance_variable_set(:@live, fake_live)
  shell.instance_variable_set(:@ui_thread, Thread.current)
end

queued_id = nil
worker = Thread.new { queued_id = shell.add_assistant_message("queued") }
worker.join
assert(shell.transcript.find_block(queued_id).nil?, "worker-thread API call is queued")
fake_live.drain
assert(shell.transcript.find_block(queued_id)[:text] == "queued", "queued API call reaches UI runtime")

shell.instance_variable_get(:@state_mutex).synchronize do
  shell.instance_variable_set(:@state, :stopped)
  shell.instance_variable_set(:@live, nil)
end
assert(shell.add_user_message("after stop").nil?, "add after stop returns nil")
assert(shell.replace_message(assistant_id, "after stop") == false, "mutate after stop returns false")

puts "AgentShell API checks passed"
