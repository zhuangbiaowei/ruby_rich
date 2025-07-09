# RubyRich - Advanced Ruby Terminal UI Toolkit

![RubyRich Demo](https://via.placeholder.com/800x400.png?text=RubyRich+Terminal+Demo)

A comprehensive Ruby terminal UI toolkit inspired by Python Rich, providing elegant formatting, advanced layouts, and professional terminal output.

## ✨ Features

### Core Text Features
- 🎨 **Rich Markup Language** - Intuitive `[bold red]text[/bold red]` syntax
- 🖥️ **Terminal Output** - Elegant formatted output with automatic color detection
- 📝 **Text Styling** - Chainable text styles with RGB/HEX color support

### Advanced Content Rendering
- 🖼️ **Syntax Highlighting** - Built-in support for 200+ programming languages
- 📄 **Markdown Rendering** - Full markdown support with terminal-optimized output
- 🌳 **Tree Display** - Beautiful hierarchical data visualization
- 📊 **Enhanced Tables** - Auto-expanding tables with rich formatting

### Layout & UI Components
- 🧩 **Panel Layouts** - Create nested layouts with borders and styles
- 📋 **Multi-Column Layouts** - Professional newspaper-style column formatting
- 🚦 **Status Indicators** - Comprehensive status symbols and progress tracking
- 📈 **Advanced Progress Bars** - Multiple styles, ETA, rate calculation, and multi-progress support

### Development Tools
- 🔍 **Object Inspection** - Rich object debugging and inspection
- 📝 **Enhanced Logging** - Structured logging with rich formatting
- ⚡ **High Performance** - Optimized for large datasets and real-time updates

## 📦 Installation

Add to Gemfile:
```ruby
gem 'ruby_rich'
```

Or install directly:
```bash
gem install ruby_rich
```

## 🚀 Quick Start

```ruby
require 'ruby_rich'

# Rich markup language
puts RubyRich::RichText.markup("[bold green]Success![/bold green] Task completed.")

# Syntax highlighting
code = "def hello\n  puts 'world'\nend"
puts RubyRich.syntax(code, 'ruby')

# Markdown rendering
markdown = "# Title\n\nThis is **bold** text."
puts RubyRich.markdown(markdown)

# Tree structure
tree = RubyRich.tree("Project")
tree.add("src").add("main.rb")
tree.add("README.md")
puts tree.render

# Status indicators
puts RubyRich.status(:success, text: "All systems operational")
puts RubyRich.status(:warning, text: "High memory usage detected")

# Enhanced progress bar
RubyRich::ProgressBar.with_progress(100, title: "Processing", show_rate: true) do |bar|
  100.times { |i| bar.advance(1); sleep(0.01) }
end
```

## 📚 Advanced Features

### Rich Markup Language
```ruby
# Basic colors and styles
puts RubyRich::RichText.markup("[red]Error message[/red]")
puts RubyRich::RichText.markup("[bold]Important text[/bold]")
puts RubyRich::RichText.markup("[italic blue]Styled text[/italic blue]")

# Combined styles
puts RubyRich::RichText.markup("[bold red]Critical Alert![/bold red]")
```

### Syntax Highlighting
```ruby
# Automatic language detection
puts RubyRich.syntax("def hello; puts 'world'; end")

# Explicit language specification
python_code = "def fibonacci(n):\n    return n if n <= 1 else fibonacci(n-1) + fibonacci(n-2)"
puts RubyRich.syntax(python_code, 'python')

# Supported languages: Ruby, Python, JavaScript, JSON, HTML, CSS, SQL, and 200+ more
```

### Markdown Rendering
```ruby
markdown_text = <<~MARKDOWN
# Project Documentation

## Features
- **Rich formatting**
- *Syntax highlighting*
- `Code blocks`

### Code Example
```ruby
puts "Hello, Ruby Rich!"
```

> This is a quote block

[Visit our website](https://example.com)
MARKDOWN

puts RubyRich.markdown(markdown_text)
```

### Tree Structure Display
```ruby
# Manual tree construction
tree = RubyRich.tree("My Project")
src = tree.add("src")
src.add("main.rb")
src.add("utils.rb")
tree.add("README.md")

# From file paths
paths = ["app/models/user.rb", "app/views/users/index.html", "config/routes.rb"]
file_tree = RubyRich::Tree.from_paths(paths, "Rails App")

# From hash structure
data = {
  "Database" => {
    "Users" => ["john", "jane"],
    "Posts" => ["post1", "post2"]
  }
}
hash_tree = RubyRich::Tree.from_hash(data, "System")
```

### Multi-Column Layouts
```ruby
layout = RubyRich.columns(total_width: 80)

# Add columns with different configurations
left_col = layout.add_column(title: "News", align: :left)
right_col = layout.add_column(title: "Updates", align: :right)

left_col.add("Breaking: Ruby Rich 2.0 released!")
left_col.add("New features include advanced layouts")
right_col.add("Performance improved by 300%")
right_col.add("Memory usage reduced by 50%")

puts layout.render(show_headers: true, show_borders: true)

# Custom column ratios
layout.set_ratios(2, 1)  # 2:1 ratio
```

### Status Indicators
```ruby
# Basic status indicators
puts RubyRich.status(:success)     # ✅ Success
puts RubyRich.status(:error)       # ❌ Error
puts RubyRich.status(:warning)     # ⚠️ Warning
puts RubyRich.status(:info)        # ℹ️ Info

# System status
puts RubyRich.status(:online)      # 🟢 Online
puts RubyRich.status(:offline)     # 🔴 Offline
puts RubyRich.status(:maintenance) # 🔧 Maintenance

# Status board
board = RubyRich::Status::StatusBoard.new(width: 50)
board.add_item("Web Server", :online, description: "Nginx running on port 80")
board.add_item("Database", :warning, description: "High connection count")
board.add_item("Cache", :error, description: "Redis connection failed")
puts board.render
```

### Enhanced Progress Bars
```ruby
# Basic progress bar with details
bar = RubyRich::ProgressBar.new(
  1000, 
  width: 40, 
  title: "Processing",
  show_percentage: true,
  show_rate: true,
  show_eta: true
)

bar.start
1000.times { |i| bar.advance(1); sleep(0.01) }
bar.finish(message: "✅ Processing completed!")

# Different styles
styles = [:default, :blocks, :arrows, :dots, :line]
styles.each do |style|
  bar = RubyRich::ProgressBar.new(50, style: style, title: style.to_s)
  # ... progress ...
end

# Multiple progress bars
multi = RubyRich::ProgressBar::MultiProgress.new
bar1 = multi.add("File 1", 100)
bar2 = multi.add("File 2", 100) 
bar3 = multi.add("File 3", 100)
multi.start
# ... update bars individually ...
multi.finish_all
```

### Enhanced Tables
```ruby
# Rich content in tables
table = RubyRich::Table.new(headers: ["Feature", "Status", "Notes"])
table.add_row([
  RubyRich::RichText.markup("[cyan]Syntax Highlighting[/cyan]"),
  RubyRich::RichText.markup("[green]✅ Complete[/green]"),
  "200+ languages supported"
])
table.add_row([
  RubyRich::RichText.markup("[cyan]Markdown Rendering[/cyan]"),
  RubyRich::RichText.markup("[yellow]🚧 Beta[/yellow]"),
  "Full CommonMark support"
])

puts table.render
```

## 🎨 Themes and Customization

```ruby
# Custom theme setup
RubyRich::RichText.set_theme({
  primary: { color: :blue, bold: true },
  secondary: { color: :cyan },
  accent: { color: :yellow, bold: true }
})

# Use themed styles
text = RubyRich::RichText.new("Important message", style: :primary)
puts text.render
```

## 🔧 Configuration

```ruby
# Global console configuration
console = RubyRich::Console.new
console.set_layout(spacing: 2, align: :center)
console.style(:header, color: :blue, bold: true)

# Custom progress bar styles
RubyRich::ProgressBar::STYLES[:custom] = {
  filled: '▓', empty: '░', prefix: '⟨', suffix: '⟩'
}
```

## 🧪 Testing & Examples

All examples and tests are located in the `examples/` directory.

Run the comprehensive test suite:
```bash
ruby examples/test_all_features.rb
```

Run the complete feature demonstration:
```bash
ruby examples/demo_all_features.rb
```

Individual feature examples:
```bash
ruby examples/test_markup.rb      # Rich markup language
ruby examples/test_syntax.rb      # Syntax highlighting
ruby examples/test_markdown.rb    # Markdown rendering
ruby examples/test_tree.rb        # Tree structures
ruby examples/test_columns.rb     # Multi-column layouts
ruby examples/test_status.rb      # Status indicators
ruby examples/test_enhanced_progress.rb  # Progress bars
```

See `examples/README.md` for detailed information about each example file.

## 📊 Performance

Ruby Rich is optimized for performance:
- Processes 10,000+ markup elements per second
- Renders large tables (1000+ rows) in milliseconds
- Minimal memory footprint with efficient object management
- Thread-safe for concurrent operations

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push branch (`git push origin feature/amazing-feature`)
5. Create Pull Request

## 📄 License

MIT License - See [LICENSE](LICENSE)

## 🙏 Acknowledgments

- Inspired by Python's [Rich](https://github.com/Textualize/rich) library
- Built with ❤️ for the Ruby community
- Special thanks to all contributors and testers

---

**Ruby Rich** - Making terminal applications beautiful, one line at a time. ✨