#!/usr/bin/env ruby
# quine-and-a-half : cheats by printing the actual file, then prints the
# bytecode for the file 

def no_op
  $some_variable ||= 1024
end

if __FILE__ == $0
  buf = File.open(__FILE__, 'r') { |f| f.read }
  code = RubyVM::InstructionSequence.compile(buf)
  puts buf
  puts code.disasm
end
