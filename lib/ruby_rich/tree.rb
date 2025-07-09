module RubyRich
  class Tree
    # 树形结构显示的字符集
    TREE_CHARS = {
      default: {
        vertical: '│',
        horizontal: '─',
        branch: '├',
        last: '└',
        space: ' '
      },
      ascii: {
        vertical: '|',
        horizontal: '-',
        branch: '+',
        last: '+',
        space: ' '
      },
      rounded: {
        vertical: '│',
        horizontal: '─',
        branch: '├',
        last: '└',
        space: ' '
      },
      double: {
        vertical: '║',
        horizontal: '═',
        branch: '╠',
        last: '╚',
        space: ' '
      }
    }.freeze

    # 树节点类
    class Node
      attr_accessor :name, :children, :data, :expanded

      def initialize(name, data: nil)
        @name = name
        @children = []
        @data = data
        @expanded = true
      end

      def add_child(child_node)
        @children << child_node
        child_node
      end

      def add(name, data: nil)
        child = Node.new(name, data: data)
        add_child(child)
        child
      end

      def leaf?
        @children.empty?
      end

      def has_children?
        !@children.empty?
      end
    end

    attr_reader :root, :style

    def initialize(root_name = 'Root', style: :default)
      @root = Node.new(root_name)
      @style = style
      @chars = TREE_CHARS[@style] || TREE_CHARS[:default]
    end

    # 从哈希构建树
    def self.from_hash(hash, root_name = 'Root', style: :default)
      tree = new(root_name, style: style)
      build_from_hash(tree.root, hash)
      tree
    end

    # 从文件路径构建树
    def self.from_paths(paths, root_name = 'Root', style: :default)
      tree = new(root_name, style: style)
      
      paths.each do |path|
        parts = path.split('/')
        current_node = tree.root
        
        parts.each do |part|
          next if part.empty?
          
          # 查找是否已存在该子节点
          existing_child = current_node.children.find { |child| child.name == part }
          
          if existing_child
            current_node = existing_child
          else
            current_node = current_node.add(part)
          end
        end
      end
      
      tree
    end

    # 添加节点到根节点
    def add(name, data: nil)
      @root.add(name, data: data)
    end

    # 渲染树形结构
    def render(show_guides: true, colors: true)
      lines = []
      render_node(@root, '', true, lines, show_guides, colors)
      lines.join("\n")
    end

    # 渲染为字符串（别名）
    def to_s
      render
    end

    private

    def self.build_from_hash(node, hash)
      hash.each do |key, value|
        child = node.add(key.to_s)
        if value.is_a?(Hash)
          build_from_hash(child, value)
        elsif value.is_a?(Array)
          value.each_with_index do |item, index|
            if item.is_a?(Hash)
              item_child = child.add("[#{index}]")
              build_from_hash(item_child, item)
            else
              child.add(item.to_s)
            end
          end
        else
          child.add(value.to_s) unless value.nil?
        end
      end
    end

    def render_node(node, prefix, is_last, lines, show_guides, colors)
      # 根节点特殊处理
      if node == @root
        if colors
          lines << "\e[1m\e[96m#{node.name}\e[0m"
        else
          lines << node.name
        end
        
        node.children.each_with_index do |child, index|
          is_child_last = (index == node.children.length - 1)
          render_node(child, '', is_child_last, lines, show_guides, colors)
        end
        return
      end

      # 构建当前行的前缀和连接符
      if show_guides
        connector = is_last ? @chars[:last] : @chars[:branch]
        current_prefix = prefix + connector + @chars[:horizontal] + @chars[:space]
      else
        current_prefix = prefix + @chars[:space] * 4
      end

      # 渲染当前节点
      node_text = if colors
        case
        when node.leaf?
          "\e[92m#{node.name}\e[0m"  # 绿色叶子节点
        when node.has_children?
          "\e[94m#{node.name}/\e[0m"  # 蓝色目录节点
        else
          node.name
        end
      else
        node.leaf? ? node.name : "#{node.name}/"
      end

      lines << current_prefix + node_text

      # 递归渲染子节点
      if node.expanded && node.has_children?
        next_prefix = if show_guides
          prefix + (is_last ? @chars[:space] : @chars[:vertical]) + @chars[:space] * 3
        else
          prefix + @chars[:space] * 4
        end

        node.children.each_with_index do |child, index|
          is_child_last = (index == node.children.length - 1)
          render_node(child, next_prefix, is_child_last, lines, show_guides, colors)
        end
      end
    end
  end
end