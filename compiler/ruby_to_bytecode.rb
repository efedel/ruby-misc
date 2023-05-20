#!/usr/bin/env ruby

require 'rubygems'
require 'json'

def generate_bytecode_file(iseq)
  File.open('/tmp/iseq_test.dat.json', 'wb') { |f|
    f.write( iseq.to_a.to_json )
  }
  File.open('/tmp/iseq_test.dat.disasm', 'wb') { |f|
    f.write( iseq.disassemble )
  }
end

if __FILE__ == $0
  ARGV.each do |arg|
    iseq = RubyVM::InstructionSequence.compile_file(arg)
    generate_bytecode_file(iseq)
  end
end
