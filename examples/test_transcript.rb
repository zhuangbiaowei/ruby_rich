#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/ruby_rich'

layout = RubyRich::Layout.new(name: :root)
transcript = RubyRich::Transcript.new
viewport = RubyRich::Viewport.new(transcript, scrollbar: true, auto_scroll: true)

transcript.add_user("介绍一下关于模型的配置，如何才能使用最高思考深度？")
transcript.add_thinking("The user is asking about model configuration. I should inspect config files and explain the exact setting.", status: "idle", collapsed: true)
transcript.add_assistant("I'll look at the configuration structure and relevant source files.")
transcript.add_tool("read_file", status: :done, result: "name: read_file\nresult: config/defaults.rb\n3 lines omitted", collapsed: true)
transcript.add_separator
transcript.add_markdown("#{RubyRich::AnsiCode.color(:blue, true)}使用 DeepSeek-V4-Pro 最高思考深度的配置#{RubyRich::AnsiCode.reset}\n\n1. 设置模型为 `deepseek-v4-pro`\n2. 设置 `reasoning_effort = \"max\"`")

transcript.attach(layout)
viewport.attach(layout)
layout.content = viewport

layout.key(:ctrl_c) { |_event, live| live.stop; false }
layout.key(:string) { |event, live| live.stop if event[:value] == "q"; false }

RubyRich::Live.start(layout, refresh_rate: 20, mouse: true) do |live|
  live.listening = true
end
