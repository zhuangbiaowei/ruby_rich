#!/usr/bin/env ruby

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
puts RubyRich::RichText.markup("[bold]Ruby Rich Terminal Library - Complete Feature Demo[/bold]")
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

# 4. 树形结构演示
puts "\n" + RubyRich::RichText.markup("[bold blue]4. Tree Structure Display[/bold blue]")
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

# 5. 状态指示器演示
puts "\n" + RubyRich::RichText.markup("[bold blue]5. Status Indicators[/bold blue]")
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

# 6. 多列布局演示
puts "\n" + RubyRich::RichText.markup("[bold blue]6. Multi-Column Layout[/bold blue]")
puts "-"*40

news_layout = RubyRich.columns(total_width: 75)
news_col = news_layout.add_column(title: "Latest News")
tech_col = news_layout.add_column(title: "Technology")

news_col.add("Ruby Rich v2.0 released with amazing new features")
news_col.add("Terminal applications now look professional")
news_col.add("Developers report 300% satisfaction increase")

tech_col.add("New syntax highlighting engine")
tech_col.add("Advanced progress tracking")
tech_col.add("Multi-platform compatibility")

puts news_layout.render(show_headers: true)
sleep(2)

# 7. 表格演示
puts "\n" + RubyRich::RichText.markup("[bold blue]7. Enhanced Tables[/bold blue]")
puts "-"*40

feature_table = RubyRich::Table.new(headers: ["Feature", "Status", "Version"])
feature_table.add_row([
  RubyRich::RichText.markup("[cyan]Rich Markup[/cyan]"),
  RubyRich::RichText.markup("[green]✅ Complete[/green]"),
  "v2.0"
])
feature_table.add_row([
  RubyRich::RichText.markup("[cyan]Syntax Highlighting[/cyan]"),
  RubyRich::RichText.markup("[green]✅ Complete[/green]"),
  "v2.0"
])
feature_table.add_row([
  RubyRich::RichText.markup("[cyan]Markdown Support[/cyan]"),
  RubyRich::RichText.markup("[green]✅ Complete[/green]"),
  "v2.0"
])

puts feature_table.render
sleep(2)

# 8. 进度条演示
puts "\n" + RubyRich::RichText.markup("[bold blue]8. Enhanced Progress Bars[/bold blue]")
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
puts RubyRich::RichText.markup("Ruby Rich Terminal Library provides [bold]everything[/bold] you need")
puts RubyRich::RichText.markup("to create [italic]beautiful[/italic] and [underline]professional[/underline] terminal applications.")
puts
puts RubyRich::RichText.markup("[cyan]Thank you for using Ruby Rich![/cyan]")
puts "="*80