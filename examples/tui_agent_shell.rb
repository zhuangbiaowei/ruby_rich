#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/ruby_rich'

app = RubyRich::AppShell.new(
  title: "Agent",
  subtitle: "DeepSeek-TUI · deepseek-v4-pro",
  model: "deepseek-v4-pro"
)

app.update_plan("tracks update_plan // /goal /cycles")
app.set_tasks([
  { label: "turn 5b4bb60d-... ", status: :in_progress },
  { label: "Composer component", status: :done },
  { label: "Transcript viewport", status: :done },
  { label: "Sidebar panels", status: :done }
])

app.add_user("介绍一下关于模型的配置，如何才能使用 DeepSeek-v4-pro 的最高的思考深度？")
app.add_thinking(
  "The user is asking about model configuration - specifically how to configure the TUI to use the DeepSeek-v4-pro model with the highest thinking depth. Let me inspect the relevant configuration and model-related code.",
  status: "done · 3.1s",
  collapsed: true
)
app.add_assistant("I'll look at the configuration documentation and model-related code to give you an accurate answer.")
app.add_tool(
  "read_file",
  status: :issue,
  result: "name: read_file\nresult: Failed to execute tool: Failed to read \\\\?\\D:\\code\\DeepSeek-TUI\\docs: access denied (os error 5)",
  collapsed: false
)
app.add_tool(
  "read",
  status: :done,
  result: "done: Searching for `thinking|reasoning|depth|v4-pro`",
  collapsed: true
)
app.add_thinking(
  "Let me now look at the key source files to understand how reasoning_effort is configured and used. I need to see:\n\n1. The configuration file structure where reasoning_effort is stored\n2. How the client applies reasoning_effort to API parameters\n3. The default model selection path",
  status: "idle",
  collapsed: false
)
app.add_assistant("Let me read the core client-side logic and the configuration documentation.")
app.add_separator
app.add_markdown(<<~TEXT)
  #{RubyRich::AnsiCode.color(:blue, true)}使用 DeepSeek-V4-Pro 最高思考深度的配置#{RubyRich::AnsiCode.reset}

  #{RubyRich::AnsiCode.color(:blue, true)}1. 设置模型为 `deepseek-v4-pro`#{RubyRich::AnsiCode.reset}

  默认情况下，`default_text_model` 已经是 `deepseek-v4-pro`。无需额外配置即可使用。

  #{RubyRich::AnsiCode.color(:blue, true)}2. 设置 `reasoning_effort = "max"`#{RubyRich::AnsiCode.reset}

  在 Composer 中输入 `/thinking` 可以插入一段可折叠 thinking；输入 `/tool` 可以插入工具调用块。
TEXT

app.start
