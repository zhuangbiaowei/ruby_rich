#!/usr/bin/env ruby

require_relative '../lib/ruby_rich'

items = [
  { label: 'Help', value: '/help', description: 'Show available commands' },
  { label: 'Status', value: '/status', description: 'Print current status' },
  { label: 'Deploy', value: '/deploy', description: 'Run deployment flow' },
  { label: 'Test', value: '/test', description: 'Execute test suite' },
  { label: 'Quit', value: '/quit', description: 'Exit this demo' }
]

status_lines = [
  'SlashInput + Layout + Live 全屏示例',
  "输入 '/' 召唤菜单，↑/↓ 选择，Enter 选中命令，Esc 关闭菜单。",
  "输入 /quit 后按 Enter 退出。"
]

layout = RubyRich::Layout.new(name: :root)
layout.split_column(
  RubyRich::Layout.new(name: :header, size: 5),
  RubyRich::Layout.new(name: :body, ratio: 1),
  RubyRich::Layout.new(name: :input, size: 10)
)

slash_input = RubyRich::SlashInput.new(
  prompt: 'Command> ',
  items: items,
  on_select: lambda { |item, _live|
    status_lines << "Selected: #{item[:label]} (#{item[:value]})"
  },
  on_submit: lambda { |value, live|
    status_lines << "Submitted: #{value}"
    live.stop if value.strip == '/quit'
  }
)

slash_input.attach(layout)

layout[:header].content = RubyRich::Panel.new(
  'RubyRich SlashInput Demo',
  title: 'Header'
)

layout[:body].content = Object.new.tap do |view|
  view.define_singleton_method(:render) do
    visible_lines = status_lines.last(20)
    panel = RubyRich::Panel.new(visible_lines.join("\n"), title: 'Event Log / Tips')
    panel.height = layout[:body].height
    panel.width = layout[:body].width
    panel.render
  end
end

layout[:input].content = Object.new.tap do |view|
  view.define_singleton_method(:render) do
    panel = RubyRich::Panel.new(slash_input.render.join("\n"), title: 'Input')
    panel.height = layout[:input].height
    panel.width = layout[:input].width
    panel.render
  end
end

RubyRich::Live.start(layout, refresh_rate: 24) do |live|
  live.listening = true
end
