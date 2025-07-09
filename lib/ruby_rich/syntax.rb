require 'rouge'

module RubyRich
  class Syntax
    # 支持的语言别名映射
    LANGUAGE_ALIASES = {
      'rb' => 'ruby',
      'py' => 'python',
      'js' => 'javascript',
      'ts' => 'typescript',
      'sh' => 'shell',
      'bash' => 'shell',
      'zsh' => 'shell',
      'yml' => 'yaml',
      'md' => 'markdown'
    }.freeze

    # 语法高亮主题颜色映射
    THEME_COLORS = {
      # Rouge token types to ANSI colors
      'Comment' => "\e[90m",           # Bright black (gray)
      'Comment.Single' => "\e[90m",
      'Comment.Multiline' => "\e[90m",
      'Comment.Preproc' => "\e[95m",   # Bright magenta
      
      'Keyword' => "\e[94m",           # Bright blue
      'Keyword.Constant' => "\e[94m",
      'Keyword.Declaration' => "\e[94m",
      'Keyword.Namespace' => "\e[94m",
      'Keyword.Pseudo' => "\e[94m",
      'Keyword.Reserved' => "\e[94m",
      'Keyword.Type' => "\e[94m",
      
      'Literal' => "\e[96m",           # Bright cyan
      'Literal.Date' => "\e[96m",
      'Literal.Number' => "\e[93m",    # Bright yellow
      'Literal.Number.Bin' => "\e[93m",
      'Literal.Number.Float' => "\e[93m",
      'Literal.Number.Hex' => "\e[93m",
      'Literal.Number.Integer' => "\e[93m",
      'Literal.Number.Oct' => "\e[93m",
      
      'Literal.String' => "\e[92m",    # Bright green
      'Literal.String.Affix' => "\e[92m",
      'Literal.String.Backtick' => "\e[92m",
      'Literal.String.Char' => "\e[92m",
      'Literal.String.Doc' => "\e[92m",
      'Literal.String.Double' => "\e[92m",
      'Literal.String.Escape' => "\e[96m",
      'Literal.String.Heredoc' => "\e[92m",
      'Literal.String.Interpol' => "\e[96m",
      'Literal.String.Other' => "\e[92m",
      'Literal.String.Regex' => "\e[91m",  # Bright red
      'Literal.String.Single' => "\e[92m",
      'Literal.String.Symbol' => "\e[95m", # Bright magenta
      
      'Name' => "\e[97m",              # Bright white
      'Name.Attribute' => "\e[93m",    # Bright yellow
      'Name.Builtin' => "\e[96m",      # Bright cyan
      'Name.Builtin.Pseudo' => "\e[96m",
      'Name.Class' => "\e[93m",        # Bright yellow
      'Name.Constant' => "\e[93m",
      'Name.Decorator' => "\e[95m",    # Bright magenta
      'Name.Entity' => "\e[93m",
      'Name.Exception' => "\e[91m",    # Bright red
      'Name.Function' => "\e[96m",     # Bright cyan
      'Name.Property' => "\e[96m",
      'Name.Label' => "\e[95m",
      'Name.Namespace' => "\e[93m",
      'Name.Other' => "\e[97m",
      'Name.Tag' => "\e[94m",          # Bright blue
      'Name.Variable' => "\e[97m",
      'Name.Variable.Class' => "\e[97m",
      'Name.Variable.Global' => "\e[97m",
      'Name.Variable.Instance' => "\e[97m",
      
      'Operator' => "\e[91m",          # Bright red
      'Operator.Word' => "\e[94m",     # Bright blue
      
      'Punctuation' => "\e[97m",       # Bright white
      
      'Error' => "\e[101m\e[97m",      # Red background, white text
      'Generic.Deleted' => "\e[91m",   # Bright red
      'Generic.Emph' => "\e[3m",       # Italic
      'Generic.Error' => "\e[91m",     # Bright red
      'Generic.Heading' => "\e[1m\e[94m", # Bold bright blue
      'Generic.Inserted' => "\e[92m",  # Bright green
      'Generic.Output' => "\e[90m",    # Bright black (gray)
      'Generic.Prompt' => "\e[1m",     # Bold
      'Generic.Strong' => "\e[1m",     # Bold
      'Generic.Subheading' => "\e[95m", # Bright magenta
      'Generic.Traceback' => "\e[91m"  # Bright red
    }.freeze

    def self.highlight(code, language = nil, theme: :default)
      new(theme: theme).highlight(code, language)
    end

    def initialize(theme: :default)
      @theme = theme
    end

    def highlight(code, language = nil)
      return code if code.nil? || code.empty?
      
      # 检测或规范化语言
      language = detect_language(code) if language.nil?
      language = normalize_language(language) if language
      
      # 如果无法检测语言，返回原始代码
      return code unless language
      
      begin
        lexer = Rouge::Lexer.find(language)
        return code unless lexer
        
        # 使用自定义格式化器
        formatter = AnsiFormatter.new
        formatter.format(lexer.lex(code))
      rescue => e
        # 如果高亮失败，返回原始代码
        code
      end
    end

    def list_languages
      Rouge::Lexer.all.map(&:tag).sort
    end

    private

    def detect_language(code)
      # 简单的语言检测启发式
      return 'ruby' if code.include?('def ') && code.include?('end')
      return 'python' if code.include?('def ') && code.include?(':')
      return 'javascript' if code.include?('function') || code.include?('=>')
      return 'html' if code.include?('<html') || code.include?('<!DOCTYPE')
      return 'css' if code.match?(/\w+\s*{[^}]*}/)
      return 'shell' if code.start_with?('#!/bin/') || code.include?('$ ')
      return 'json' if code.strip.start_with?('{') && code.include?(':')
      return 'yaml' if code.include?('---') || code.match?(/^\w+:/)
      
      nil
    end

    def normalize_language(language)
      return nil if language.nil?
      language = language.to_s.downcase.strip
      LANGUAGE_ALIASES[language] || language
    end

    # 自定义 ANSI 格式化器
    class AnsiFormatter
      def format(tokens)
        output = ''
        tokens.each do |token, value|
          color_code = THEME_COLORS[token.qualname] || 
                      THEME_COLORS[token.token_chain.map(&:qualname).find { |t| THEME_COLORS[t] }] ||
                      ''
          
          if color_code.empty?
            output << value
          else
            output << "#{color_code}#{value}\e[0m"
          end
        end
        output
      end
    end
  end
end