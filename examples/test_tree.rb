#!/usr/bin/env ruby

require_relative '../lib/ruby_rich'

puts "Testing Tree Display:"
puts "=" * 50

# 创建基本树结构
puts "\n1. Basic Tree Structure:"
tree = RubyRich.tree("Project")
root_node = tree.add("src")
root_node.add("main.rb")
root_node.add("utils.rb")

lib_node = tree.add("lib")
lib_node.add("helper.rb")
models_node = lib_node.add("models")
models_node.add("user.rb")
models_node.add("post.rb")

tree.add("README.md")
tree.add("Gemfile")

puts tree.render

# 从文件路径创建树
puts "\n2. Tree from File Paths:"
paths = [
  "app/controllers/application_controller.rb",
  "app/controllers/users_controller.rb",
  "app/models/user.rb",
  "app/models/post.rb",
  "app/views/users/index.html.erb",
  "app/views/users/show.html.erb",
  "app/views/layouts/application.html.erb",
  "config/routes.rb",
  "config/database.yml",
  "public/images/logo.png",
  "public/stylesheets/app.css"
]

file_tree = RubyRich::Tree.from_paths(paths, "Rails App")
puts file_tree.render

# 从哈希创建树
puts "\n3. Tree from Hash:"
data = {
  "Database" => {
    "Users" => ["john_doe", "jane_smith", "bob_wilson"],
    "Posts" => {
      "Published" => ["post_1", "post_2"],
      "Drafts" => ["draft_1", "draft_2", "draft_3"]
    }
  },
  "Config" => {
    "Environment" => "production",
    "Debug" => false
  }
}

hash_tree = RubyRich::Tree.from_hash(data, "System")
puts hash_tree.render

# 不同样式的树
puts "\n4. Different Tree Styles:"

puts "\nASCII Style:"
ascii_tree = RubyRich.tree("ASCII Tree", style: :ascii)
ascii_tree.add("folder1").add("file1.txt")
ascii_tree.add("file2.txt")
puts ascii_tree.render

puts "\nDouble Line Style:"
double_tree = RubyRich.tree("Double Tree", style: :double)
double_tree.add("config").add("settings.json")
double_tree.add("readme.txt")
puts double_tree.render

puts "\nTree test completed!"