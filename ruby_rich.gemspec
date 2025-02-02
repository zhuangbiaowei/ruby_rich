require_relative "lib/ruby_rich/version"

Gem::Specification.new do |s|
  s.name        = 'ruby_rich'
  s.version     = RubyRich::VERSION
  s.summary     = "Rich text formatting and console output for Ruby"
  s.description = "A Ruby gem providing rich text formatting, progress bars, tables and other console output enhancements"
  s.authors     = ["zhuang biaowei"]
  s.email       = 'zbw@kaiyuanshe.org'
  s.files       = Dir["lib/**/*.rb"]
  s.homepage    = 'https://github.com/zhuangbiaowei/ruby_rich'
  s.license     = 'MIT'
  
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'minitest', '~> 5.0'
  
  s.required_ruby_version = '>= 2.7.0'
end