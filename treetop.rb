#!/usr/bin/env ruby
# Treetop (.tt) grammars in ruby
# http://treetop.rubyforge.org/using_in_ruby.html
require 'polyglot'
require 'treetop'

Treetop.load "arithmetic"

parser = ArithmeticParser.new
if parser.parse('1+1')
    puts 'success'
else
    puts 'failure'
end

# ----------------------------------------------------------------------
parser = ArithmeticParser.new
input = 'x = 2; y = x+3;'

# Temporarily override an option:
result1 = parser.parse(input, :consume_all_input => false)
puts "consumed #{parser.index} characters"

parser.consume_all_input = false
result1 = parser.parse(input)
puts "consumed #{parser.index} characters"

# Continue the parse with the next character:
result2 = parser.parse(input, :index => parser.index)

# Parse, but match rule `variable` instead of the normal root rule:
parser.parse(input, :root => :variable)
parser.root = :variable # Permanent setting
