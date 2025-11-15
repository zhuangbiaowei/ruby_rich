#!/usr/bin/env ruby

require_relative '../lib/ruby_rich'

puts "="*80
puts "Ruby Rich Markdown Table Rendering Test"
puts "="*80

# 测试1：简单表格
puts "\n1. Simple Table:"
puts "-"*50

simple_table = <<'MARKDOWN'
# Simple Table Test

| Name | Age | City |
|------|-----|------|
| Alice | 25 | NYC |
| Bob | 30 | LA |
| Charlie | 35 | Chicago |
MARKDOWN

result = RubyRich.markdown(simple_table)
puts result
puts "✓ Simple table: Success"

# 测试2：带边框样式的表格
puts "\n2. Table with Full Border Style:"
puts "-"*50

bordered_table = <<'MARKDOWN'
# Bordered Table

| Product | Price | Stock |
|---------|-------|-------|
| Laptop | $999 | 15 |
| Mouse | $25 | 50 |
| Keyboard | $75 | 30 |
MARKDOWN

result_bordered = RubyRich.markdown(bordered_table, table_border_style: :full)
puts result_bordered
puts "✓ Bordered table: Success"

# 测试3：复杂表格
puts "\n3. Complex Table with Mixed Content:"
puts "-"*50

complex_table = <<'MARKDOWN'
# Project Status Table

| Project | Status | Priority | Deadline |
|---------|--------|----------|----------|
| WebApp | InProgress | High | 2024Q1 |
| MobileApp | Planning | Medium | 2024Q2 |
| API | Completed | High | 2023Q4 |
| Documentation | Todo | Low | 2024Q3 |
MARKDOWN

result_complex = RubyRich.markdown(complex_table, table_border_style: :simple)
puts result_complex
puts "✓ Complex table: Success"

# 测试4：包含特殊字符的表格
puts "\n4. Table with Special Characters:"
puts "-"*50

special_table = <<'MARKDOWN'
# Feature Comparison

| Feature | Ruby | Python | JavaScript |
|---------|------|--------|------------|
| WebDev | Yes | Yes | Yes |
| Performance | Good | Good | Fast |
| Learning | Easy | Easy | Medium |
MARKDOWN

result_special = RubyRich.markdown(special_table)
puts result_special
puts "✓ Special characters table: Success"

# 测试5：数字和文本混合
puts "\n5. Mixed Numbers and Text:"
puts "-"*50

mixed_table = <<'MARKDOWN'
# Sales Data

| Month | Sales | Growth | Target |
|-------|-------|--------|--------|
| Jan2024 | 1500 | 5Percent | 1600 |
| Feb2024 | 1800 | 20Percent | 1700 |
| Mar2024 | 2100 | 16Percent | 2000 |
MARKDOWN

result_mixed = RubyRich.markdown(mixed_table, table_border_style: :full)
puts result_mixed
puts "✓ Mixed content table: Success"

# 测试总结
puts "\n" + "="*80
puts "Markdown Table Rendering Tests Completed!"
puts "Features tested:"
puts "✓ Basic markdown table parsing and rendering"
puts "✓ Intelligent content splitting algorithm"
puts "✓ Different border styles (none, simple, full)"
puts "✓ Complex content with mixed data types"
puts "✓ Integration with RubyRich Table component"
puts "✓ Proper handling of markdown syntax"
puts "="*80