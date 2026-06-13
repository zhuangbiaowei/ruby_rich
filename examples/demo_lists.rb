#!/usr/bin/env ruby
# frozen_string_literal: true
# 演示：嵌套列表层级符号 + 任务列表
require_relative "../lib/ruby_rich"

puts RubyRich::RichText.markup("[bold cyan]列表渲染演示 (v0.5.0 新增)[/bold cyan]")
puts "=" * 60

puts RubyRich::RichText.markup("[bold]三级无序列表 + 颜色区分[/bold]")
puts RubyRich.markdown(<<~'MD', width: 50)
- 第一层项目 (cyan)
  - 第二层项目 (magenta)
    - 第三层项目 (yellow)
    - 同层另一个
  - 回到第二层
- 回到第一层
MD

puts RubyRich::RichText.markup("[bold]有序列表嵌套[/bold]")
puts RubyRich.markdown(<<~'MD', width: 50)
1. 第一步骤
   1. 子步骤 1.1
      1. 子步骤 1.1.1
   2. 子步骤 1.2
2. 第二步骤
MD

puts RubyRich::RichText.markup("[bold]混合嵌套 (无序含有序)[/bold]")
puts RubyRich.markdown(<<~'MD', width: 50)
- 外层无序
  1. 内层有序第一
  2. 内层有序第二
- 回到无序
MD

puts RubyRich::RichText.markup("[bold]任务列表 （[x] 完成 [ ] 未完成）[/bold]")
puts RubyRich.markdown(<<~'MD', width: 50)
- [x] 已完成的需求分析
- [x] 已完成的设计文档
- [ ] 待开发的模块A
- [ ] 待测试的模块B
  - [x] 子任务已完成
  - [ ] 子任务待办
MD

puts RubyRich::RichText.markup("[green]✅ 列表嵌套/任务列表演示完成[/green]")
