#!/usr/bin/env ruby

require_relative '../lib/ruby_rich'

puts "Testing Syntax Highlighting:"
puts "=" * 50

# Test Ruby code highlighting
ruby_code = <<'RUBY'
def hello_world(name)
  puts "Hello, #{name}!"
  return true
end

# Comment example
result = hello_world("Ruby")
RUBY

puts "\n" + RubyRich::RichText.markup("[bold]Ruby Code:[/bold]")
puts RubyRich.syntax(ruby_code, 'ruby')

# Test Python code highlighting
python_code = <<'PYTHON'
def hello_world(name):
    """A simple greeting function"""
    print(f"Hello, {name}!")
    return True

# Comment example
result = hello_world("Python")
PYTHON

puts "\n" + RubyRich::RichText.markup("[bold]Python Code:[/bold]")
puts RubyRich.syntax(python_code, 'python')

# Test JavaScript code highlighting  
js_code = <<'JS'
function helloWorld(name) {
    // Comment example
    console.log(`Hello, ${name}!`);
    return true;
}

const result = helloWorld("JavaScript");
JS

puts "\n" + RubyRich::RichText.markup("[bold]JavaScript Code:[/bold]")
puts RubyRich.syntax(js_code, 'javascript')

# Test auto-detection
puts "\n" + RubyRich::RichText.markup("[bold]Auto-detected Ruby:[/bold]")
auto_ruby = "def test\n  puts 'auto-detected'\nend"
puts RubyRich.syntax(auto_ruby)

# Test JSON highlighting
json_code = <<'JSON'
{
  "name": "John Doe",
  "age": 30,
  "city": "New York",
  "active": true,
  "skills": ["ruby", "python", "javascript"]
}
JSON

puts "\n" + RubyRich::RichText.markup("[bold]JSON Code:[/bold]")
puts RubyRich.syntax(json_code, 'json')

puts "\nSyntax highlighting test completed!"