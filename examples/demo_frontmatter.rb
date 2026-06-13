#!/usr/bin/env ruby
# frozen_string_literal: true
# 演示：YAML Frontmatter 提取与渲染
require_relative "../lib/ruby_rich"

puts RubyRich::RichText.markup("[bold cyan]Frontmatter 渲染演示 (v0.5.0 新增)[/bold cyan]")
puts "=" * 60

puts RubyRich::RichText.markup("[bold]1. 少量属性 — 水平表格 (< 5 对)[/bold]")
puts RubyRich.markdown(<<~'MD', width: 55, table_border_style: :full)

---
title: "RuboCop 配置"
severity: warning
enabled: true
---

# RuboCop 配置说明

本文档描述了项目的 RuboCop 静态分析配置。
MD

puts RubyRich::RichText.markup("[bold]2. 大量属性 — 垂直表格 (>= 5 对)[/bold]")
puts RubyRich.markdown(<<~'MD', width: 60, table_border_style: :full)

---
title: "项目配置"
description: Ruby Rich 终端 UI 工具库
version: "0.5.0"
author: zhuangbiaowei
license: MIT
repository: https://github.com/example/ruby_rich
tags:
  - ruby
  - terminal
  - tui
  - markdown
---

# 项目文档

完整配置如上所示。
MD

puts RubyRich::RichText.markup("[bold]3. 无 Frontmatter — 正常渲染[/bold]")
puts RubyRich.markdown(<<~'MD', width: 55)

# 普通文档

此文档没有 Frontmatter 元数据块。

正文内容从这里开始。
- 列表项
- **粗体**
MD

puts RubyRich::RichText.markup("[green]✅ Frontmatter 演示完成[/green]")
