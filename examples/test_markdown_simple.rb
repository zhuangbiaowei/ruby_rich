#!/usr/bin/env ruby

require_relative '../lib/ruby_rich'

simple_markdown = <<'MARKDOWN'
# Hello World

This is a **simple** markdown test with *italic* text.

## Code Example

```ruby
puts "Hello, Ruby!"
```

### Lists

- Item 1
- Item 2
- Item 3

> This is a quote

[This is a link](https://example.com)

---

That's all!
MARKDOWN

puts "Testing Simple Markdown Rendering:"
puts "=" * 50
puts

begin
  rendered = RubyRich.markdown(simple_markdown)
  puts rendered
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(5)
end

puts "Markdown rendering test completed!"