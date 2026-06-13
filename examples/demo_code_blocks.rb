#!/usr/bin/env ruby
# frozen_string_literal: true
# 演示：代码块边框、行号、语言标签
require_relative "../lib/ruby_rich"

puts RubyRich::RichText.markup("[bold cyan]代码块渲染演示 (v0.5.0 新增)[/bold cyan]")
puts "=" * 60

# 多语言语法高亮
puts RubyRich::RichText.markup("\n[bold]多语言代码块[/bold]")
puts RubyRich.markdown(<<~'MD', width: 55)

```ruby
# Ruby: 斐波那契数列
def fib(n)
  return n if n <= 1
  fib(n - 1) + fib(n - 2)
end
puts fib(10)
```

```python
# Python: 快速排序
def quicksort(arr):
    if len(arr) <= 1:
        return arr
    pivot = arr[0]
    return quicksort([x for x in arr[1:] if x < pivot]) + [pivot] + quicksort([x for x in arr[1:] if x >= pivot])
```
MD

# 短代码 + 长行截断
puts RubyRich::RichText.markup("[bold]单行代码 + 长行截断[/bold]")
puts RubyRich.markdown(<<~'MD', width: 40)

```sh
echo "Hello, Ruby Rich!"
```
```js
const greeting = "This is a very long JavaScript line that will be truncated in the terminal display"
```
MD

puts RubyRich::RichText.markup("[green]✅ 代码块边框/行号/语言标签演示完成[/green]")
