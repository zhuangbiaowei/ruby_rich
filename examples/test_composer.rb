#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/ruby_rich'

layout = RubyRich::Layout.new(name: :root)
layout.split_column(
  RubyRich::Layout.new(name: :log, ratio: 1),
  RubyRich::Layout.new(name: :composer, size: 8)
)

log = ["Composer demo", "Type / for commands. Enter submits. Up/Down browse history."]
composer = RubyRich::Composer.new(
  placeholder: "编写任务或使用 /。",
  commands: [
    { label: "help", value: "/help", description: "Show help" },
    { label: "plan", value: "/plan", description: "Update plan" },
    { label: "quit", value: "/quit", description: "Exit demo" }
  ],
  on_select: ->(command, _live) { log << "selected #{command[:value]}" },
  on_submit: lambda { |value, live|
    log << "submitted #{value}"
    live.stop if value == "/quit"
  }
)
composer.focus.attach(layout[:composer])
layout[:composer].content = composer

layout.key(:ctrl_c) { |_event, live| live.stop; false }

layout[:log].content = Object.new.tap do |view|
  view.define_singleton_method(:render) do
    panel = RubyRich::Panel.new(log.last(20).join("\n"), title: "Log", border_style: :blue, title_align: :left)
    panel.width = layout[:log].width
    panel.height = layout[:log].height
    panel.render
  end
end

RubyRich::Live.start(layout, refresh_rate: 20, mouse: true) do |live|
  live.listening = true
end
