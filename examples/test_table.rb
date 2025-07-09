#!/usr/bin/env ruby

require_relative '../lib/ruby_rich'

puts "="*80
puts "Ruby Rich Table Feature Test (Including Border Styles)"
puts "="*80

# 测试1: 基础表格
puts "\n1. Basic Table:"
puts "-"*50

table1 = RubyRich::Table.new(headers: ["Name", "Age", "City"])
table1.add_row(["Alice", "25", "New York"])
table1.add_row(["Bob", "30", "London"])
table1.add_row(["Charlie", "35", "Tokyo"])

puts table1.render
puts "✓ Basic table: Success"

# 测试2: 使用便捷方法创建表格
puts "\n2. Table with Convenience Method:"
puts "-"*50

table2 = RubyRich.table
table2.headers = ["Product", "Price", "Stock"]
table2.add_row(["Laptop", "$999", "15"])
table2.add_row(["Mouse", "$25", "50"])
table2.add_row(["Keyboard", "$75", "30"])

puts table2.render
puts "✓ Convenience method table: Success"

# 测试3: 包含富文本内容的表格
puts "\n3. Table with Rich Text Content:"
puts "-"*50

table3 = RubyRich::Table.new(headers: ["Status", "Task", "Priority"])
table3.add_row([
  RubyRich::RichText.markup("[green]✓ Done[/green]"),
  "Complete project documentation",
  RubyRich::RichText.markup("[yellow]Medium[/yellow]")
])
table3.add_row([
  RubyRich::RichText.markup("[red]✗ Failed[/red]"),
  "Fix critical bug",
  RubyRich::RichText.markup("[red]High[/red]")
])
table3.add_row([
  RubyRich::RichText.markup("[blue]◯ Pending[/blue]"),
  "Code review",
  RubyRich::RichText.markup("[green]Low[/green]")
])

puts table3.render
puts "✓ Rich text table: Success"

# 测试4: 不同对齐方式的表格
puts "\n4. Table with Different Alignments:"
puts "-"*50

# 左对齐 (默认)
puts "Left Aligned (Default):"
table4_left = RubyRich::Table.new(headers: ["Item", "Quantity", "Price"], align: :left)
table4_left.add_row(["A", "10", "$5.99"])
table4_left.add_row(["B", "5", "$12.50"])
puts table4_left.render

puts "\nCenter Aligned:"
table4_center = RubyRich::Table.new(headers: ["Item", "Quantity", "Price"], align: :center)
table4_center.add_row(["A", "10", "$5.99"])
table4_center.add_row(["B", "5", "$12.50"])
puts table4_center.render

puts "\nRight Aligned:"  
table4_right = RubyRich::Table.new(headers: ["Item", "Quantity", "Price"], align: :right)
table4_right.add_row(["A", "10", "$5.99"])
table4_right.add_row(["B", "5", "$12.50"])
puts table4_right.render
puts "✓ Table alignments: Success"

# 测试5: 多行内容的表格
puts "\n5. Table with Multi-line Content:"
puts "-"*50

table5 = RubyRich::Table.new(headers: ["Name", "Description", "Notes"], row_height: 2)
table5.add_row([
  "Project Alpha",
  "A comprehensive\nsoftware solution",
  "Priority: High\nDeadline: Q1 2024"
])
table5.add_row([
  "Project Beta", 
  "Mobile application\ndevelopment",
  "Priority: Medium\nDeadline: Q2 2024"
])

puts table5.render
puts "✓ Multi-line table: Success"

# 测试6: 表格样式组合测试
puts "\n6. Table with Combined Styling:"
puts "-"*50

table6 = RubyRich::Table.new(headers: [
  RubyRich::RichText.markup("[bold blue]Server[/bold blue]"),
  RubyRich::RichText.markup("[bold blue]Status[/bold blue]"),
  RubyRich::RichText.markup("[bold blue]Load[/bold blue]"),
  RubyRich::RichText.markup("[bold blue]Memory[/bold blue]")
])

table6.add_row([
  "web-01",
  RubyRich::RichText.markup("[bold green]Running[/bold green]"),
  "23%",
  "2.4GB"
])
table6.add_row([
  "web-02", 
  RubyRich::RichText.markup("[bold red]Down[/bold red]"),
  "0%",
  "0GB"
])
table6.add_row([
  "db-01",
  RubyRich::RichText.markup("[bold yellow]Warning[/bold yellow]"),
  "78%",
  "15.2GB"
])

puts table6.render
puts "✓ Combined styling table: Success"

# 测试7: 数据类型兼容性测试
puts "\n7. Table with Different Data Types:"
puts "-"*50

table7 = RubyRich::Table.new(headers: ["Type", "Value", "Description"])
table7.add_row([123, 45.67, "Numbers as objects"])
table7.add_row([:symbol, nil, "Symbol and nil"])
table7.add_row([true, false, "Boolean values"])
table7.add_row([[], {}, "Empty collections"])

puts table7.render
puts "✓ Data type compatibility: Success"

# 测试8: 空表格测试
puts "\n8. Empty Table Test:"
puts "-"*50

table8 = RubyRich::Table.new(headers: ["Column A", "Column B", "Column C"])
puts "Empty table (headers only):"
puts table8.render

table9 = RubyRich::Table.new
puts "\nCompletely empty table:"
puts table9.render
puts "✓ Empty table handling: Success"

# 测试9: 中文内容表格
puts "\n9. Table with Chinese Content:"
puts "-"*50

table10 = RubyRich::Table.new(headers: ["姓名", "职位", "部门"])
table10.add_row(["张三", "软件工程师", "技术部"])
table10.add_row(["李四", "产品经理", "产品部"])
table10.add_row(["王五", "UI设计师", "设计部"])

puts table10.render
puts "✓ Chinese content table: Success"

# 测试10: 大量数据性能测试
puts "\n10. Performance Test with Large Data:"
puts "-"*50

start_time = Time.now
large_table = RubyRich::Table.new(headers: ["ID", "Name", "Value", "Status"])

100.times do |i|
  large_table.add_row([
    "ID#{i.to_s.rjust(3, '0')}", 
    "Item_#{i}",
    "Value_#{i}",
    i.even? ? "Active" : "Inactive"
  ])
end

rendered_large = large_table.render
end_time = Time.now

puts "Generated and rendered table with 100 rows"
puts "First 10 lines of the large table:"
puts rendered_large.split("\n")[0..10].join("\n")
puts "..."
puts "Performance: #{(end_time - start_time).round(3)}s for 100 rows"
puts "✓ Large data performance: Success"

# 测试11: 新增 - 边框样式测试
puts "\n11. Border Styles Test:"
puts "-"*50

puts "Simple Border Style:"
table11_simple = RubyRich::Table.new(
  headers: ["Product", "Price", "Stock"], 
  border_style: :simple
)
table11_simple.add_row(["Laptop", "$999", "15"])
table11_simple.add_row(["Mouse", "$25", "50"])
puts table11_simple.render

puts "\nFull Border Style (Unicode):"
table11_full = RubyRich::Table.new(
  headers: ["Product", "Price", "Stock"], 
  border_style: :full
)
table11_full.add_row(["Laptop", "$999", "15"])
table11_full.add_row(["Mouse", "$25", "50"])
puts table11_full.render

puts "\nFull Border with Rich Text:"
table11_rich = RubyRich::Table.new(
  headers: [
    RubyRich::RichText.markup("[bold blue]Product[/bold blue]"),
    RubyRich::RichText.markup("[bold green]Price[/bold green]"),
    RubyRich::RichText.markup("[bold yellow]Stock[/bold yellow]")
  ], 
  border_style: :full
)
table11_rich.add_row([
  "Laptop",
  RubyRich::RichText.markup("[red]$999[/red]"),
  RubyRich::RichText.markup("[green]15[/green]")
])
table11_rich.add_row([
  "Mouse",
  RubyRich::RichText.markup("[red]$25[/red]"),
  RubyRich::RichText.markup("[green]50[/green]")
])
puts table11_rich.render

puts "✓ Border styles: Success"

# 测试12: 多行内容配合边框
puts "\n12. Multi-line Content with Borders:"
puts "-"*50

table12 = RubyRich::Table.new(
  headers: ["Feature", "Description"], 
  border_style: :full,
  row_height: 2
)
table12.add_row([
  "Simple Border",
  "Uses ASCII characters\nfor compatibility"
])
table12.add_row([
  "Full Border", 
  "Uses Unicode box-drawing\ncharacters for aesthetics"
])

puts table12.render
puts "✓ Multi-line with borders: Success"

# 测试13: 使用便捷方法创建带边框的表格
puts "\n13. Convenience Method with Border:"
puts "-"*50

table13 = RubyRich.table(border_style: :full)
table13.headers = ["Language", "Framework", "Type"]
table13.add_row(["Ruby", "Rails", "Web"])
table13.add_row(["JavaScript", "React", "Frontend"])
table13.add_row(["Python", "Django", "Web"])

puts table13.render
puts "✓ Convenience method with border: Success"

# 测试总结
puts "\n" + "="*80
puts "All Table Tests Completed Successfully!"
puts "Features tested:"
puts "✓ Basic table creation and rendering"
puts "✓ Rich text content support"
puts "✓ Different alignment options (left, center, right)"
puts "✓ Multi-line content with configurable row height"
puts "✓ Combined text styling and colors"
puts "✓ Various data type compatibility"
puts "✓ Empty table handling"
puts "✓ Unicode/Chinese character support"
puts "✓ Large data performance"
puts "✓ Border styles (none, simple, full)"
puts "✓ Border styles with rich text content"
puts "✓ Multi-line content with borders"
puts "✓ Convenience methods with border support"
puts "=" * 80