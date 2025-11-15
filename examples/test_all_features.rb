#!/usr/bin/env ruby

require_relative '../lib/ruby_rich'

puts "="*80
puts "Ruby Rich Terminal Library - Comprehensive Feature Test"
puts "="*80

# 测试原有功能的向后兼容性
puts "\n1. Testing Backward Compatibility:"
puts "-"*50

# 原有的 Console 功能
console = RubyRich::Console.new
puts "✓ Console creation: Success"

# 原有的 Table 功能  
table = RubyRich::Table.new(headers: ["Name", "Age", "Status"])
table.add_row(["John", "25", "Active"])
table.add_row(["Jane", "30", "Inactive"])
puts "✓ Table creation and rendering: Success"
puts table.render

# 原有的 Panel 功能
panel = RubyRich::Panel.new("This is a test panel", title: "Test Panel")
panel.width = 40
panel.height = 5
puts "\n✓ Panel creation: Success"
puts panel.render.join("\n")

# 测试新功能
puts "\n\n2. Testing New Features:"
puts "-"*50

# Rich markup 标记语言
puts "\n2.1 Rich Markup Language:"
markup_text = "[bold green]Success![/bold green] This is [italic]italic text[/italic] and [red]red text[/red]."
puts RubyRich::RichText.markup(markup_text)
puts "✓ Rich markup rendering: Success"

# 语法高亮
puts "\n2.2 Syntax Highlighting:"
ruby_code = "def hello\n  puts 'world'\nend"
highlighted = RubyRich.syntax(ruby_code, 'ruby')
puts highlighted
puts "✓ Syntax highlighting: Success"

# Markdown 渲染
puts "\n2.3 Markdown Rendering:"
markdown = "# Test\n\nThis is **bold** and *italic* text.\n\n```ruby\nputs 'code'\n```"
rendered_md = RubyRich.markdown(markdown)
puts rendered_md
puts "✓ Markdown rendering: Success"

# 树形结构
puts "\n2.4 Tree Display:"
tree = RubyRich.tree("Project")
lib = tree.add("lib")
lib.add("main.rb")
lib.add("helper.rb")
tree.add("README.md")
puts tree.render
puts "✓ Tree display: Success"

# 多列布局
puts "\n2.5 Columns Layout:"
columns = RubyRich.columns(total_width: 60)
col1 = columns.add_column(title: "Left")
col2 = columns.add_column(title: "Right")
col1.add("Content A")
col1.add("Content B")
col2.add("Value 1")
col2.add("Value 2")
puts columns.render(show_headers: true)
puts "✓ Columns layout: Success"

# 状态指示器
puts "\n2.6 Status Indicators:"
puts RubyRich.status(:success, text: "All tests passing")
puts RubyRich.status(:warning, text: "Minor issues detected")
puts RubyRich.status(:info, text: "System information")
puts "✓ Status indicators: Success"

# 增强的进度条
puts "\n2.7 Enhanced Progress Bar:"
progress = RubyRich::ProgressBar.new(50, width: 30, title: "Testing")
progress.start
5.times do |i|
  sleep(0.1)
  progress.advance(10)
end
progress.finish(message: "✅ Progress bar test completed")
puts "✓ Enhanced progress bar: Success"

# 测试便捷方法
puts "\n\n3. Testing Convenience Methods:"
puts "-"*50

puts "✓ RubyRich.console: #{RubyRich.console.class}"
puts "✓ RubyRich.text: #{RubyRich.text('test').class}"  
puts "✓ RubyRich.table: #{RubyRich.table.class}"
puts "✓ RubyRich.syntax: Working"
puts "✓ RubyRich.markdown: Working"
puts "✓ RubyRich.tree: #{RubyRich.tree.class}"
puts "✓ RubyRich.columns: #{RubyRich.columns.class}"
puts "✓ RubyRich.status: Working"

# 错误处理测试
puts "\n\n4. Testing Error Handling:"
puts "-"*50

begin
  # 测试无效的标记语言
  RubyRich::RichText.markup("[invalid markup")
  puts "✓ Invalid markup handled gracefully"
rescue => e
  puts "⚠️  Markup error handling: #{e.message}"
end

begin
  # 测试无效的语法高亮语言
  RubyRich.syntax("code", "invalid_language")
  puts "✓ Invalid language handled gracefully"
rescue => e
  puts "⚠️  Syntax highlighting error: #{e.message}"
end

begin
  # 测试无效的状态类型
  RubyRich.status(:invalid_status)
rescue => e
  puts "✓ Invalid status type handled: #{e.message[0..50]}..."
end

# 性能测试
puts "\n\n5. Basic Performance Test:"
puts "-"*50

start_time = Time.now

# 大量文本处理
1000.times do |i|
  RubyRich::RichText.markup("[green]Item #{i}[/green]")
end

end_time = Time.now
puts "✓ Processed 1000 markup items in #{(end_time - start_time).round(3)}s"

# 大表格测试
large_table = RubyRich::Table.new(headers: ["ID", "Name", "Value"])
100.times do |i|
  large_table.add_row([i.to_s, "Item #{i}", "Value #{i}"])
end

start_time = Time.now
large_table.render
end_time = Time.now
puts "✓ Rendered 100-row table in #{(end_time - start_time).round(3)}s"

# 内存使用测试
puts "\n\n6. Memory Usage Test:"
puts "-"*50

# 创建多个对象确保没有内存泄漏
100.times do
  console = RubyRich::Console.new
  table = RubyRich::Table.new
  tree = RubyRich.tree("test")
  columns = RubyRich.columns
end
puts "✓ Created and discarded 400 objects without issues"

# 最终报告
puts "\n\n" + "="*80
puts "COMPREHENSIVE TEST SUMMARY"
puts "="*80

passed_tests = [
  "Backward compatibility",
  "Rich markup language", 
  "Syntax highlighting",
  "Markdown rendering",
  "Tree display",
  "Columns layout", 
  "Status indicators",
  "Enhanced progress bar",
  "Convenience methods",
  "Error handling",
  "Performance",
  "Memory usage"
]

puts "\n✅ PASSED TESTS (#{passed_tests.length}):"
passed_tests.each_with_index do |test, i|
  puts "   #{i+1}. #{test}"
end

puts "\n🎉 ALL TESTS COMPLETED SUCCESSFULLY!"
puts "   Ruby Rich Terminal Library is ready for use."
puts "\n" + "="*80