#!/usr/bin/env ruby

require_relative '../lib/ruby_rich'

puts "Testing Status Indicators:"
puts "=" * 60

# 基本状态指示器
puts "\n1. Basic Status Indicators:"
puts RubyRich.status(:success)
puts RubyRich.status(:error)
puts RubyRich.status(:warning)
puts RubyRich.status(:info)

# 进度状态
puts "\n2. Progress Status:"
puts RubyRich.status(:pending)
puts RubyRich.status(:running)
puts RubyRich.status(:completed)
puts RubyRich.status(:failed)

# 自定义文本
puts "\n3. Custom Status Text:"
puts RubyRich.status(:success, text: "Database connection established")
puts RubyRich.status(:error, text: "Failed to load configuration file")
puts RubyRich.status(:warning, text: "Memory usage is high")

# 系统状态
puts "\n4. System Status:"
puts RubyRich.status(:online)
puts RubyRich.status(:offline)
puts RubyRich.status(:maintenance)

# 安全状态
puts "\n5. Security Status:"
puts RubyRich.status(:secure)
puts RubyRich.status(:insecure)

# 等级状态
puts "\n6. Priority Levels:"
puts RubyRich.status(:low)
puts RubyRich.status(:medium)
puts RubyRich.status(:high)
puts RubyRich.status(:critical)

# 静态进度条
puts "\n7. Static Progress Bars:"
[25, 50, 75, 100].each do |progress|
  puts RubyRich::Status.progress_bar(progress, 100, width: 30)
end

puts "\n8. Different Progress Bar Styles:"
puts "Filled: " + RubyRich::Status.progress_bar(60, 100, style: :filled)
puts "Blocks: " + RubyRich::Status.progress_bar(60, 100, style: :blocks)
puts "Dots:   " + RubyRich::Status.progress_bar(60, 100, style: :dots)

# 状态板
puts "\n9. Status Board:"
board = RubyRich::Status::StatusBoard.new(width: 50)
board.add_item("Web Server", :online, description: "Nginx running on port 80")
board.add_item("Database", :online, description: "PostgreSQL v13.2")
board.add_item("Cache", :warning, description: "Redis memory usage at 85%")
board.add_item("Backup", :failed, description: "Last backup failed at 2AM")
board.add_item("SSL Certificate", :secure)

puts board.render

# 左对齐状态板
puts "\n10. Left-aligned Status Board:"
left_board = RubyRich::Status::StatusBoard.new(width: 45)
left_board.add_item("API Gateway", :online)
left_board.add_item("Load Balancer", :maintenance)
left_board.add_item("Monitoring", :running)

puts left_board.render(show_descriptions: false, align_status: :left)

# 模拟加载动画（短时间演示）
puts "\n11. Loading Animation Demo (3 seconds):"
spinner_thread = RubyRich::Status.spinner(type: :dots, text: "Processing data...")
sleep(3)
spinner_thread.kill
RubyRich::Status.stop_spinner(final_message: "✅ Processing completed!")

puts "\nStatus indicators test completed!"