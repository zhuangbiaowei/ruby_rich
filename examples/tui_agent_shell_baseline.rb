#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/ruby_rich'

layout = RubyRich::Layout.new(name: :root)
layout.split_column(
  RubyRich::Layout.new(name: :main, ratio: 1),
  RubyRich::Layout.new(name: :composer, size: 5),
  RubyRich::Layout.new(name: :status, size: 1)
)

layout[:main].split_row(
  RubyRich::Layout.new(name: :transcript, ratio: 1),
  RubyRich::Layout.new(name: :sidebar, size: 56)
)

layout[:sidebar].split_column(
  RubyRich::Layout.new(name: :plan, ratio: 1),
  RubyRich::Layout.new(name: :tasks, ratio: 1)
)

messages = [
  "#{RubyRich::AnsiCode.color(:blue, true)}Agent#{RubyRich::AnsiCode.reset}  DeepSeek-TUI · deepseek-v4-pro",
  "",
  "#{RubyRich::AnsiCode.color(:white, true)}... thinking idle#{RubyRich::AnsiCode.reset}",
  "#{RubyRich::AnsiCode.italic}Let me now look at the key source files to understand how reasoning_effort is configured and used.#{RubyRich::AnsiCode.reset}",
  "",
  "#{RubyRich::AnsiCode.color(:blue, true)}●#{RubyRich::AnsiCode.reset} Let me read the core client-side logic and the configuration documentation.",
  "",
  "#{RubyRich::AnsiCode.color(:white, true)}... thinking idle#{RubyRich::AnsiCode.reset}",
  "#{RubyRich::AnsiCode.italic}Now I have a comprehensive understanding. Let me also check the config file generation.#{RubyRich::AnsiCode.reset}",
  "",
  "#{RubyRich::AnsiCode.color(:blue, true)}使用 DeepSeek-V4-Pro 最高思考深度的配置#{RubyRich::AnsiCode.reset}",
  "",
  "#{RubyRich::AnsiCode.color(:blue, true)}1. 设置模型为 `deepseek-v4-pro`#{RubyRich::AnsiCode.reset}",
  "默认情况下，`default_text_model` 已经是 `deepseek-v4-pro`。"
]

composer = RubyRich::SlashInput.new(
  prompt: '',
  items: [
    { label: 'help', value: '/help', description: 'Show commands' },
    { label: 'model', value: '/model', description: 'Change model' },
    { label: 'quit', value: '/quit', description: 'Exit demo' }
  ],
  on_submit: lambda { |value, live|
    messages << "#{RubyRich::AnsiCode.color(:blue, true)}●#{RubyRich::AnsiCode.reset} #{value}"
    live.stop if value.strip == '/quit'
  }
)

composer.attach(layout)

layout[:transcript].content = Object.new.tap do |view|
  view.define_singleton_method(:render) do
    title = 'Transcript'
    panel = RubyRich::Panel.new(messages.join("\n"), title: title, border_style: :blue, title_align: :left)
    panel.width = layout[:transcript].width
    panel.height = layout[:transcript].height
    panel.render
  end
end

layout[:plan].content = Object.new.tap do |view|
  view.define_singleton_method(:render) do
    panel = RubyRich::Panel.new('tracks update_plan // /goal /cycles', title: 'Plan', border_style: :blue, title_align: :left)
    panel.width = layout[:plan].width
    panel.height = layout[:plan].height
    panel.render
  end
end

layout[:tasks].content = Object.new.tap do |view|
  view.define_singleton_method(:render) do
    panel = RubyRich::Panel.new("turn baseline-demo (in_progress)\nNo active tasks", title: 'Tasks', border_style: :blue, title_align: :left)
    panel.width = layout[:tasks].width
    panel.height = layout[:tasks].height
    panel.render
  end
end

layout[:composer].content = Object.new.tap do |view|
  view.define_singleton_method(:render) do
    text = composer.value.empty? && !composer.menu_open? ? "编写任务或使用 /。" : composer.render.join("\n")
    panel = RubyRich::Panel.new(text, title: 'Composer', border_style: :blue, title_align: :left)
    panel.width = layout[:composer].width
    panel.height = layout[:composer].height
    panel.render
  end
end

layout[:status].content = Object.new.tap do |view|
  view.define_singleton_method(:render) do
    "#{RubyRich::AnsiCode.color(:blue, true)}agent#{RubyRich::AnsiCode.reset} · deepseek-v4-pro"
  end
end

RubyRich::Live.start(layout, refresh_rate: 24) do |live|
  live.listening = true
end
