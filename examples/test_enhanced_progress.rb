#!/usr/bin/env ruby

require_relative '../lib/ruby_rich'

puts "Testing Enhanced Progress Bar System:"
puts "=" * 60

# 基本进度条
puts "\n1. Basic Progress Bar:"
bar = RubyRich::ProgressBar.new(100, width: 40, title: "Download")
bar.start

10.times do |i|
  sleep(0.1)
  bar.advance(10)
end
bar.finish(message: "✅ Download completed!")

# 不同样式的进度条
puts "\n2. Different Progress Bar Styles:"

styles = [:default, :blocks, :arrows, :dots, :line]

styles.each do |style|
  puts "\n#{style.to_s.capitalize} style:"
  bar = RubyRich::ProgressBar.new(50, width: 30, style: style, title: style.to_s)
  bar.start
  
  5.times do |i|
    sleep(0.05)
    bar.advance(10)
  end
  bar.finish
end

# 带详细信息的进度条
puts "\n3. Progress Bar with Details:"
detailed_bar = RubyRich::ProgressBar.new(
  1000, 
  width: 40, 
  title: "Processing", 
  show_percentage: true,
  show_rate: true,
  show_eta: true
)
detailed_bar.start

20.times do |i|
  sleep(0.1)
  detailed_bar.advance(50)
end
detailed_bar.finish(message: "🎉 Processing finished successfully!")

# 手动设置进度
puts "\n4. Manual Progress Setting:"
manual_bar = RubyRich::ProgressBar.new(100, width: 35, title: "Upload")
manual_bar.start

[10, 25, 40, 60, 75, 90, 100].each do |progress|
  sleep(0.2)
  manual_bar.set_progress(progress)
end
manual_bar.finish

# 使用回调的进度条
puts "\n5. Progress Bar with Block:"
RubyRich::ProgressBar.with_progress(100, width: 35, title: "Backup", show_rate: true) do |bar|
  100.times do |i|
    sleep(0.02)
    bar.advance(1)
  end
end

# 多进度条（模拟）
puts "\n6. Multiple Progress Bars:"
multi = RubyRich::ProgressBar::MultiProgress.new

bar1 = multi.add("File 1", 100, width: 30)
bar2 = multi.add("File 2", 100, width: 30)
bar3 = multi.add("File 3", 100, width: 30)

multi.start

# 打印多个空行为多进度条腾出空间
puts "\n\n"

# 模拟不同速度的进度
30.times do |i|
  sleep(0.1)
  
  # 不同的进度速度
  bar1.advance(4) if i % 1 == 0
  bar2.advance(2) if i % 2 == 0  
  bar3.advance(3) if i % 3 == 0
  
  multi.render_all
  
  break if bar1.completed? && bar2.completed? && bar3.completed?
end

multi.finish_all
puts "All files processed!"

puts "\nEnhanced progress bar test completed!"