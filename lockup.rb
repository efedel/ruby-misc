#!/usr/bin/env ruby1.9
# run external program  via fork/popen

exec_prog = nil

class ExecProg
  attr_reader :prog
  def initialize( prog )
    @prog = prog
  end

  def start()
    `#{@prog}`
    # TODO
  end

  def abort()
    # TODO
  end
end

require 'timeout'

child_pid = nil
begin
  status = Timeout::timeout(10) {
    IO.popen("yes") do |pipe|
      child_pid = pipe.pid
      pipe.readlines
    end
  }
rescue Timeout::Error => e
  begin
    Process.kill 'INT', child_pid
  rescue Errno::ESRCH => e
    # nop
  end
end

exit

puts "START"
  pid = fork {
    begin
      status = Timeout::timeout(10) {
        `yes`
      }
    rescue Exception => e
      puts "CAUGHT #{e}"
      exit 1
    end
  }
  #waitpid(pid)
puts "END"

