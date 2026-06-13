#!/usr/bin/env ruby
# frozen_string_literal: true
# 演示：Mermaid 图表渲染 (Pie 图 + fallback)
require_relative "../lib/ruby_rich"

puts RubyRich::RichText.markup("[bold cyan]Mermaid 图表演示 (v0.5.0 新增)[/bold cyan]")
puts "=" * 60

puts RubyRich::RichText.markup("\n[bold]1. Pie 饼图[/bold]")
puts RubyRich.markdown(<<~'MD', width: 55)

```mermaid
pie title 浏览器市场份额
    "Chrome" : 64.5
    "Safari" : 18.8
    "Firefox" : 3.4
    "Edge" : 5.2
    "Other" : 8.1
```
MD

puts RubyRich::RichText.markup("\n[bold]2. Pie 图 (无标题)[/bold]")
puts RubyRich.markdown(<<~'MD', width: 55)

```mermaid
pie
    "A" : 70
    "B" : 30
```
MD

puts RubyRich::RichText.markup("\n[bold]3. 流程图 (fallback — 显示源码)[/bold]")
puts RubyRich.markdown(<<~'MD', width: 55)

```mermaid
flowchart TD
    A[开始] --> B{是否通过?}
    B -->|是| C[部署上线]
    B -->|否| D[修复问题]
    D --> B
```
MD

puts RubyRich::RichText.markup("\n[bold]4. 时序图 (fallback — 显示源码)[/bold]")
puts RubyRich.markdown(<<~'MD')

```mermaid
sequenceDiagram
    Client->>Server: GET /api/data
    Server->>DB: SELECT * FROM users
    DB-->>Server: results
    Server-->>Client: JSON response
```
MD

puts RubyRich::RichText.markup("[green]✅ Mermaid 图表演示完成[/green]")
