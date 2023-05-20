#!/usr/bin/env ruby
# anoother fork/detach/wait test

require 'thread'
puts 'Launching child...'
pid = Process.fork do 
  puts 'IN CHILD'
  10.times do
    x = Math.exp(1024)
    puts "child calc #{x}"
  end
  exit 0
end

puts 'IN PARENT'
puts 'Detaching child...'
Process.detach(pid)
sleep 0.1
10.times do 
  print '.'
  #Thread.pass
  #sleep 0.1 # yield
end

puts 'Exiting...'
Process.waitall
exit 0
