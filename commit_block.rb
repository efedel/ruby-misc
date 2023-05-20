#!/usr/bin/env ruby
# test code for using blocks to implement compound- and micro-operations, 
# with a commit-to-storage after a compounf-op

class CommitBlock < Proc
  attr_reader :in_commit
  def initialize
    @in_commit = true
    super
  end
end

def commit_after(&block)
  no_commit = defined?(in_commit) ? true : false

  # set up CommitProc and state
  p = CommitBlock.new do 
        block.call
        puts 'Commit' unless no_commit
      end

  in_commit = true

  # yield to block
  p.call

  # perform commit
  # in real use, this would write to database or some such
  puts "COMMIT!"
end

# perform a granular/atomic operation
def micro_op(arg)
  commit_after {
    # This is just a no-op: actual operations would be handled here based
    # on what type of object arg actually is (token-stream, bytecode op, etc)
    puts "Micro (#{arg})"
  }
end

# perform a compound operation consisting of many micro-ops, then
# commit the result to disk/db/memory
def compound_op(args)
  commit_after {
    puts "Compound IN (#{args})"
    args.each { |arg| micro_op(arg) }
    puts "Compound OUT"
  }
end

def main
  compound_op( [1,3,5,7,9] )
end

if __FILE__ == $0
  main
end
