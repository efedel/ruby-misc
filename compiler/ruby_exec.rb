#!/usr/bin/env ruby

def execute_bytecode(buf)
  # TODO!
end

if __FILE__ == $0
  ARGV.inject(0) do |rv, arg|
    # execute bytecode in each file, returning result as output
    File.open(arg, 'rb') { |f| rv = execute_bytecode(f.read) }
    rv
  end
end
