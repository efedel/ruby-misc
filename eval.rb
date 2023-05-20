#!/usr/bin/env ruby
#  test of eval-implementation for DSL

class Dsl
  def initialize
    @binding = binding()
  end

  def eval(cmd)
    fn_str, rest = cmd.split(/[[:space:]]/, 2)
    fn = fn_str.to_sym
    if self.methods.include? fn
      self.send(fn, rest)
    elsif fn_str == :'?'
      self.HELP(rest)
    elsif rest.start_with?('<-')
      self.send_to(fn, rest[2..-1].strip)
    else
      @binding.eval(cmd)
    end
  end

  def send_to(dest, cmd)
    puts "ASSIGN '#{cmd}' TO #{dest}"
  end

  def R(str)
    puts "[R] #{str}"
  end

  def HELP(str)
    puts "HELP TOPIC: #{str}"
  end

  def LOAD(str)
  end

  def FETCH(str)
  end

end
