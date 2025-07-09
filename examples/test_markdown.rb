#!/usr/bin/env ruby

require_relative '../lib/ruby_rich'

markdown_text = <<'MARKDOWN'
# Ruby Rich Terminal Library

A **powerful** and *elegant* terminal output library for Ruby applications.

## Features

- Rich text formatting with ANSI colors
- Syntax highlighting for 200+ languages  
- Markdown rendering
- Table layouts
- Progress bars
- And much more!

### Code Example

Here's a simple Ruby example:

```ruby
def hello_world(name)
  puts "Hello, #{name}!"
  return true  
end

result = hello_world("Ruby Rich")
```

And here's some Python:

```python
def greet(name):
    """Simple greeting function"""
    print(f"Hello, {name}!")
    return True
```

### Lists

**Features:**
- Fast and efficient
- Easy to use
- Highly customizable
- Cross-platform

**Installation:**
1. Add to Gemfile
2. Run `bundle install`
3. Require the library
4. Start using!

### Links and Images

Visit our [GitHub repository](https://github.com/example/ruby_rich) for more information.

![Ruby Logo](https://ruby-lang.org/logo.png "The Ruby Programming Language")

### Quotes

> "Ruby Rich is an amazing library that makes terminal output beautiful and easy to manage."
> 
> — Happy User

### Tables

| Feature | Status | Priority |
|---------|--------|----------|
| Rich Text | ✅ Done | High |
| Syntax Highlighting | ✅ Done | High |
| Markdown | 🚧 In Progress | High |
| Tables | ✅ Done | Medium |

---

**Note:** This library is under active development. More features coming soon!

~~This text is struck through~~

Some **bold** and *italic* text with `inline code`.
MARKDOWN

puts "Testing Markdown Rendering:"
puts "=" * 50
puts

rendered = RubyRich.markdown(markdown_text)
puts rendered

puts "Markdown rendering test completed!"