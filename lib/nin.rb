require 'toml-rb'

require_relative 'nin/version'
require_relative 'nin/store'
require_relative 'nin/item'
require_relative 'nin/todo'

module Nin
  def self.run
    case ARGV[0]
    when 'l'
      Nin::Todo.new.list
    when 'a'
      Nin::Todo.new.add(ARGV[1..-1].join(' '))
    when 'u'
      Nin::Todo.new.update(ARGV[1].to_i, ARGV[2..-1].join(' '))
    when 'd'
      Nin::Todo.new.delete(ARGV[1].to_i)
    else
      puts "\nUSAGE: nin COMMAND [arguments...]\n\n"
      puts "COMMANDS:"
      puts "  l             List all todos"
      puts "  a desc        Add a todo"
      puts "  u id desc     Update a todo"
      puts "  d id          Remove a todo"
    end
  end
end
