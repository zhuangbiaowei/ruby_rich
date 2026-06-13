#!/usr/bin/env ruby

require 'bundler/setup'
require_relative '../lib/ruby_rich'

puts "\e[2J\e[H"  # 清屏并移动光标到顶部

# 创建标题
title = <<~TITLE
███████╗██╗   ██╗██████╗ ██╗   ██╗    ██████╗ ██╗ ██████╗██╗  ██╗
██╔══██║██║   ██║██╔══██╗╚██╗ ██╔╝    ██╔══██╗██║██╔════╝██║  ██║
███████║██║   ██║██████╔╝ ╚████╔╝     ██████╔╝██║██║     ███████║
██╔══██║██║   ██║██╔══██╗  ╚██╔╝      ██╔══██╗██║██║     ██╔══██║
██║  ██║╚██████╔╝██████╔╝   ██║       ██║  ██║██║╚██████╗██║  ██║
╚═╝  ╚═╝ ╚═════╝ ╚═════╝    ╚═╝       ╚═╝  ╚═╝╚═╝ ╚═════╝╚═╝  ╚═╝
TITLE

puts RubyRich::RichText.markup("[bold cyan]#{title}[/bold cyan]")
puts RubyRich::RichText.markup("[bold]Ruby Rich Terminal Library - Complete Feature Demo (v0.5.0)[/bold]")
puts "="*80

sleep(1)

# 1. Rich Markup 演示
puts "\n" + RubyRich::RichText.markup("[bold blue]1. Rich Markup Language[/bold blue]")
puts "-"*40
markup_examples = [
  "[green]✅ Success message[/green]",
  "[red]❌ Error message[/red]",
  "[yellow]⚠️ Warning message[/yellow]",
  "[bold]Important text[/bold]",
  "[italic]Emphasized text[/italic]",
  "[underline]Underlined text[/underline]",
  "[bold red]Critical alert![/bold red]"
]

markup_examples.each do |example|
  puts "  " + RubyRich::RichText.markup(example)
  sleep(0.3)
end

# 2. 语法高亮演示
puts "\n" + RubyRich::RichText.markup("[bold blue]2. Syntax Highlighting[/bold blue]")
puts "-"*40

code_examples = {
  "Ruby" => "def fibonacci(n)\n  return n if n <= 1\n  fibonacci(n-1) + fibonacci(n-2)\nend",
  "Python" => "def fibonacci(n):\n    if n <= 1:\n        return n\n    return fibonacci(n-1) + fibonacci(n-2)",
  "JavaScript" => "function fibonacci(n) {\n    if (n <= 1) return n;\n    return fibonacci(n-1) + fibonacci(n-2);\n}"
}

code_examples.each do |lang, code|
  puts "\n#{lang}:"
  puts RubyRich.syntax(code, lang.downcase)
  sleep(1)
end

# 3. Markdown 渲染演示
puts "\n" + RubyRich::RichText.markup("[bold blue]3. Markdown Rendering[/bold blue]")
puts "-"*40

markdown_sample = <<~MARKDOWN
# Ruby Rich Features

## Core Capabilities
- **Rich text** formatting
- *Syntax highlighting*
- `Code snippets`

> "This library transforms terminal output from boring to beautiful!"

### Installation
```bash
gem install ruby_rich
```
MARKDOWN

puts RubyRich.markdown(markdown_sample)
sleep(2)

# 4. 代码块增强 ⭐ NEW v0.5.0
puts "\n" + RubyRich::RichText.markup("[bold cyan]4. Enhanced Code Blocks ⭐ NEW[/bold cyan]")
puts "-"*40

puts RubyRich.markdown(<<~'MD', width: 55)

```ruby
# 斐波那契 (带行号 + 边框)
def fib(n)
  n <= 1 ? n : fib(n-1) + fib(n-2)
end
puts fib(10)
```
MD
sleep(2)

# 5. 列表增强 ⭐ NEW v0.5.0
puts "\n" + RubyRich::RichText.markup("[bold cyan]5. Enhanced Lists ⭐ NEW[/bold cyan]")
puts "-"*40

puts RubyRich.markdown(<<~'MD', width: 50)
### 嵌套列表 (三级符号 + 颜色)
- 第一层 • (cyan)
  - 第二层 ◦ (magenta)
    - 第三层 ▸ (yellow)
  - 同层
- 回到第一层

### 任务列表
- [x] 需求分析完成
- [x] 接口设计完成
- [ ] 模块开发
- [ ] 集成测试
MD
sleep(2)

# 6. LaTeX 数学公式 ⭐ NEW v0.5.0
puts "\n" + RubyRich::RichText.markup("[bold cyan]6. LaTeX Math → Unicode ⭐ NEW[/bold cyan]")
puts "-"*40

puts RubyRich.markdown(<<~'MD', width: 60)
行内公式:  $e^{i\pi} + 1 = 0$ , $\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$

块级公式:
$$
\sum_{i=1}^{n} i = \frac{n(n+1)}{2}
$$

常用符号: $\alpha \beta \gamma$ , $x \leq y \neq z$ , $A \to B$ , $\infty$
MD
sleep(2)

# 7. Mermaid 图表 ⭐ NEW v0.5.0
puts "\n" + RubyRich::RichText.markup("[bold cyan]7. Mermaid Diagrams ⭐ NEW[/bold cyan]")
puts "-"*40

puts RubyRich.markdown(<<~'MD', width: 55)

```mermaid
pie title 技术栈分布
    "Ruby" : 40
    "Python" : 30
    "Rust" : 20
    "JS" : 10
```
MD
sleep(2)

# 8. Frontmatter ⭐ NEW v0.5.0
puts "\n" + RubyRich::RichText.markup("[bold cyan]8. Frontmatter Extraction ⭐ NEW[/bold cyan]")
puts "-"*40

puts RubyRich.markdown(<<~'MD', width: 50, table_border_style: :full)

---
title: "文档标题"
author: zhuangbiaowei
version: "0.5.0"
---

# 带元数据的文档

前端元数据自动提取并以表格形式展示。
MD
sleep(2)

# 9. 树形结构演示
puts "\n" + RubyRich::RichText.markup("[bold blue]9. Tree Structure Display[/bold blue]")
puts "-"*40

project_tree = RubyRich.tree("Ruby Rich Project")
src = project_tree.add("src")
src.add("console.rb")
src.add("table.rb")
src.add("progress_bar.rb")

lib = project_tree.add("lib")
components = lib.add("components")
components.add("text.rb")
components.add("panel.rb")
components.add("tree.rb")

project_tree.add("README.md")
project_tree.add("Gemfile")

puts project_tree.render
sleep(2)

# 10. 状态指示器演示
puts "\n" + RubyRich::RichText.markup("[bold blue]10. Status Indicators[/bold blue]")
puts "-"*40

services = [
  ["Web Server", :online],
  ["Database", :online],
  ["Cache", :warning],
  ["Backup Service", :failed],
  ["SSL Certificate", :secure],
  ["Load Balancer", :maintenance]
]

services.each do |service, status|
  puts "#{service.ljust(20)} #{RubyRich.status(status)}"
  sleep(0.5)
end

# 11. 多列布局演示
puts "\n" + RubyRich::RichText.markup("[bold blue]11. Multi-Column Layout[/bold blue]")
puts "-"*40

news_layout = RubyRich.columns(total_width: 75)
news_col = news_layout.add_column(title: "Latest News")
tech_col = news_layout.add_column(title: "Technology")

news_col.add("Ruby Rich v0.5.0 released with LaTeX, Mermaid, and Frontmatter support")
news_col.add("Terminal Markdown rendering now rivals desktop-class tools")
news_col.add("Code blocks with line numbers and syntax highlighting")

tech_col.add("LaTeX → Unicode math converter")
tech_col.add("Mermaid pie chart renderer")
tech_col.add("Adaptive-width tables")

puts news_layout.render(show_headers: true)
sleep(2)

# 12. 表格演示
puts "\n" + RubyRich::RichText.markup("[bold blue]12. Enhanced Tables[/bold blue]")
puts "-"*40

feature_table = RubyRich::Table.new(headers: ["Feature", "Status", "v0.5.0"])
feature_table.add_row([
  RubyRich::RichText.markup("[cyan]Rich Markup[/cyan]"),
  RubyRich::RichText.markup("[green]✅ Complete[/green]"),
  "v2.0"
])
feature_table.add_row([
  RubyRich::RichText.markup("[cyan]Code Blocks[/cyan]"),
  RubyRich::RichText.markup("[green]✅ Enhanced[/green]"),
  "⭐ NEW"
])
feature_table.add_row([
  RubyRich::RichText.markup("[cyan]LaTeX Math[/cyan]"),
  RubyRich::RichText.markup("[green]✅ New[/green]"),
  "⭐ NEW"
])
feature_table.add_row([
  RubyRich::RichText.markup("[cyan]Mermaid Pie[/cyan]"),
  RubyRich::RichText.markup("[green]✅ New[/green]"),
  "⭐ NEW"
])
feature_table.add_row([
  RubyRich::RichText.markup("[cyan]Frontmatter[/cyan]"),
  RubyRich::RichText.markup("[green]✅ New[/green]"),
  "⭐ NEW"
])
feature_table.add_row([
  RubyRich::RichText.markup("[cyan]Theme System[/cyan]"),
  RubyRich::RichText.markup("[green]✅ New[/green]"),
  "⭐ NEW"
])

puts feature_table.render
sleep(2)

# 13. 进度条演示
puts "\n" + RubyRich::RichText.markup("[bold blue]13. Enhanced Progress Bars[/bold blue]")
puts "-"*40

puts "Different styles:"

[:default, :blocks, :dots, :line].each do |style|
  bar = RubyRich::ProgressBar.new(40, width: 30, style: style, title: style.to_s.capitalize)
  bar.start

  8.times do |i|
    sleep(0.1)
    bar.advance(5)
  end
  bar.finish
  puts
end

# 最终消息
puts "\n" + "="*80
puts RubyRich::RichText.markup("[bold green]🎉 Demo Complete! 🎉[/bold green]")
puts
puts RubyRich::RichText.markup("Ruby Rich Terminal Library v0.5.0 provides [bold]everything[/bold] you need")
puts RubyRich::RichText.markup("to create [italic]beautiful[/italic] and [underline]professional[/underline] terminal Markdown output.")
puts
puts RubyRich::RichText.markup("[bold cyan]New in v0.5.0:[/bold cyan]")
puts RubyRich::RichText.markup("  • [green]Code blocks[/green] with border, line numbers, language label")
puts RubyRich::RichText.markup("  • [green]Nested lists[/green] with • ◦ ▸ markers and color-coded levels")
puts RubyRich::RichText.markup("  • [green]Task lists[/green] with ☑/☐ checkboxes")
puts RubyRich::RichText.markup("  • [green]LaTeX → Unicode[/green] math formula converter")
puts RubyRich::RichText.markup("  • [green]Mermaid pie[/green] chart renderer")
puts RubyRich::RichText.markup("  • [green]YAML frontmatter[/green] extraction and table display")
puts RubyRich::RichText.markup("  • [green]MarkdownTheme[/green] colour system")
puts RubyRich::RichText.markup("  • [green]Adaptive-width[/green] table columns")
puts
puts RubyRich::RichText.markup("[cyan]Thank you for using Ruby Rich![/cyan]")
puts "="*80
