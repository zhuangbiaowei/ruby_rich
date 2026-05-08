# RubyRich - Ruby 终端富文本工具库

![RubyRich Demo](./images/screen.png)

受 Python Rich 启发开发的现代化 Ruby 终端 UI 工具库

## ✨ 功能特性

- 🖥️ **终端输出** - 自动色彩检测的优雅格式化输出
- 📊 **进度条** - 带速度/时间预估的多功能进度条
- 🧩 **面板布局** - 创建带边框和样式的嵌套布局
- 🎨 **文本样式** - 支持 RGB/HEX 颜色的链式文本样式
- 📜 **表格系统** - 自动扩展的表格支持列对齐和样式
- 🖼️ **语法高亮** - 内置 200+ 编程语言支持
- 📈 **状态显示** - 带实时动画的持久状态显示

## 📦 安装

添加到 Gemfile:
```ruby
gem 'ruby_rich'
```

或直接安装:
```bash
gem install ruby_rich
```

## 🚀 快速开始

```ruby
require 'ruby_rich'

# 初始化控制台
console = RubyRich::Console.new

# 基础样式打印
console.print("[bold green]操作成功![/bold green] [italic]文件已保存[/italic]")

# 创建信息面板
panel = RubyRich::Panel.new(
  "[blue]系统信息[/blue]\nCPU: 42%\n内存: 38%",
  title: "状态",
  border_style: "round",
  padding: 1
)
console.print(panel)

# 生成表格
table = RubyRich::Table.new("用户报告", columns: 3)
table.add_row("姓名", "年龄", "状态")
table.add_row("[cyan]张三[/cyan]", "28", "[green]活跃[/green]")
console.print(table)

# 进度条使用
RubyRich::ProgressBar.new("处理中...").with_progress do |bar|
  10.times do |i|
    sleep 0.1
    bar.advance(10, desc: "步骤 #{i+1}")
  end
end
```

## 📚 高级功能

### 主题系统
```ruby
theme = RubyRich::Theme.agent_dark

puts theme.style("Agent", :accent)
puts theme.style("thinking collapsed", :thinking)

custom = RubyRich::Theme.new(
  border: :blue,
  focused_border: :cyan,
  roles: {
    accent: { color: :blue, bright: true, bold: true },
    warning: { color: :yellow, bright: true }
  }
)
```

### 布局系统
```ruby
layout = RubyRich::Layout.new(
  header: "[bold]应用仪表盘[/bold]",
  footer: "[dim]按 F1 获取帮助[/dim]",
  columns: 2
)
layout.add_column("主内容区", width: 70)
layout.add_column("侧边栏")
console.print(layout)
```

### Agent TUI 应用壳
```ruby
shell = RubyRich::AgentShell.new(
  title: "Agent",
  subtitle: "DeepSeek-TUI · deepseek-v4-pro",
  model: "deepseek-v4-pro"
)

shell.on_submit { |text, attachments| handle_submit(text, attachments) }
shell.on_interrupt { interrupt_agent }
shell.on_mode_toggle { |mode| switch_agent_mode(mode) }
shell.on_command { |command| run_command(command) }

user_id = shell.add_user_message("如何配置模型？")
assistant_id = shell.add_assistant_message("", streaming: true)
shell.append_to_message(assistant_id, "把模型设为 `deepseek-v4-pro`。")

tool_id = shell.start_tool_call(name: "read_file", input: "config.yml", status: :running)
shell.finish_tool_call(tool_id, status: :done, output: "ok")

shell.update_tasks([{ label: "turn demo", status: :in_progress }])
shell.update_status("agent · ready")
shell.show_token_usage(input: 120, output: 48, total: 168)
shell.start
```

`AgentShell` 的所有输出条目都会返回稳定 id。消息和工具调用条目支持 append、replace、remove。UI 运行中从工作线程调用输出 API 时，会通过 Live 的 UI 动作队列转交给 UI runtime。Shell 停止后，新增条目返回 `nil`，修改/删除类调用返回 `false`。

如果需要直接控制 transcript 条目模型，可以使用 `RubyRich::Transcript::Store`:

```ruby
store = RubyRich::Transcript::Store.new

entry = store.add(type: :assistant, content: "", metadata: { streaming: true })
store.append(entry.id, "delta")
store.replace(entry.id, "complete response")
store.update(entry.id) { |item| item.status = :done }
store.remove(entry.id)

tool = store.add(type: :tool, content: "input", status: :running, name: "read_file")
store.update(tool.id) { |item| item.status = :done }
store.expand(tool.id)
```

支持的条目类型包括 `:user`、`:assistant`、`:thinking`、`:tool`、`:tool_result`、`:system`、`:error`、`:markdown`、`:diff`、`:separator`、`:progress`。Markdown 和 diff 条目会按内容版本和宽度缓存渲染结果，刷新时不会反复重算未变化的长内容。

运行完整交互示例:
```bash
ruby -Ilib examples/tui_agent_shell.rb
ruby -Ilib examples/demo_agent_tui_complete.rb
ruby -Ilib examples/demo_agent_tui_complete.rb --smoke
ruby -Ilib examples/test_agent_shell_api.rb
ruby -Ilib examples/test_transcript_store.rb
```

## 🤝 贡献指南

1. Fork 本仓库
2. 新建功能分支 (`git checkout -b feature/新功能`)
3. 提交修改 (`git commit -m '添加新功能'`)
4. 推送分支 (`git push origin feature/新功能`)
5. 提交 Pull Request

## 📄 开源协议

MIT 协议 - 详见 [LICENSE](LICENSE)
