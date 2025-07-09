#!/usr/bin/env ruby

require_relative '../lib/ruby_rich'

puts "Testing Columns Layout:"
puts "=" * 80

# 基本的三列布局
puts "\n1. Basic Three-Column Layout:"
layout = RubyRich.columns(total_width: 80, gutter_width: 2)

# 添加三列
col1 = layout.add_column(title: "News")
col2 = layout.add_column(title: "Sports")  
col3 = layout.add_column(title: "Weather")

# 添加内容到各列
col1.add("Breaking: Ruby Rich library released!")
col1.add("New features include syntax highlighting")
col1.add("and markdown rendering capabilities.")
col1.add("")
col1.add("Users report significant improvement")
col1.add("in terminal output quality.")

col2.add("Football: Local team wins championship")
col2.add("after defeating rivals 3-1 in final.")
col2.add("")
col2.add("Basketball season starts next month")
col2.add("with new players joining the roster.")

col3.add("Today: Sunny, 25°C")
col3.add("Tomorrow: Partly cloudy, 22°C")
col3.add("Weekend: Rain expected")
col3.add("")
col3.add("UV Index: High")
col3.add("Humidity: 65%")

puts layout.render(show_headers: true)

# 带边框的两列布局
puts "\n2. Two-Column Layout with Borders:"
bordered_layout = RubyRich.columns(total_width: 70, gutter_width: 1)

left_col = bordered_layout.add_column(title: "Features", align: :left)
right_col = bordered_layout.add_column(title: "Status", align: :center)

left_col.add("Rich Text Markup")
left_col.add("Syntax Highlighting")
left_col.add("Markdown Rendering")
left_col.add("Tree Display")
left_col.add("Column Layout")

right_col.add("✅ Complete")
right_col.add("✅ Complete")
right_col.add("✅ Complete")
right_col.add("✅ Complete")
right_col.add("🚧 In Progress")

puts bordered_layout.render(show_headers: true, show_borders: true)

# 不等宽列布局
puts "\n3. Unequal Width Columns (2:1:1 ratio):"
ratio_layout = RubyRich.columns(total_width: 80)

main_col = ratio_layout.add_column(title: "Main Content")
sidebar1 = ratio_layout.add_column(title: "Links")
sidebar2 = ratio_layout.add_column(title: "Ads")

# 设置列宽比例 2:1:1
ratio_layout.set_ratios(2, 1, 1)

main_col.add("Welcome to Ruby Rich Terminal Library")
main_col.add("")
main_col.add("This powerful library transforms your")
main_col.add("terminal output with rich formatting,")
main_col.add "colors, and advanced layout features."
main_col.add("")
main_col.add("Perfect for CLI applications, reports,")
main_col.add("and any Ruby script that needs")
main_col.add("beautiful terminal output.")

sidebar1.add("• GitHub")
sidebar1.add("• Docs")
sidebar1.add("• Examples")
sidebar1.add("• Support")

sidebar2.add("Try Pro!")
sidebar2.add("Special")
sidebar2.add("Offer")

puts ratio_layout.render(show_headers: true)

# 右对齐和居中对齐示例
puts "\n4. Different Alignments:"
align_layout = RubyRich.columns(total_width: 60)

left_col = align_layout.add_column(title: "Left", align: :left)
center_col = align_layout.add_column(title: "Center", align: :center)
right_col = align_layout.add_column(title: "Right", align: :right)

["Item 1", "Item 2", "Item 3"].each do |item|
  left_col.add(item)
  center_col.add(item)
  right_col.add(item)
end

puts align_layout.render(show_headers: true)

puts "\nColumns layout test completed!"