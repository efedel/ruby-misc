#!/usr/bin/env ruby

KEYS = [ :pid, :comm, :state, :ppid, :pgrp, :session, :tty_nr, :tpgid, 
         :flags, :minflt, :cminflt, :majflt, :cmajflt, :utime, :stime, 
         :cutime, :cstime, :priority, :nice, :num_threads, :itrealvalue, 
         :starttime, :vsize, :rss, :rsslim, :startcode, :endcode, :startstack, 
         :kstkesp, :kstkeip, :signal, :blocked, :sigignore, :sigcatch, :wchan, 
         :nswap, :cnswap, :exit_signal, :processor, :rt_priority, :policy, 
         :delayacct_blkio_ticks, :quest_time, :cquest_time ]

def display_proc_stat(path)
  buf = File.read(path)
  arr = buf.split
  h = {}
  KEYS.each_with_index { |k, idx| h[k] = arr[idx] }
  puts h.inspect
end

if __FILE__ == $0
  raise "Usage: #{$0} PID" if ARGV.count == 0
  pid = Integer(ARGV.shift)
  raise "Invalid numeric argument" if ! pid
  fname = File.join('', 'proc', pid.to_s, 'stat')
  raise "Invalid PID" if ! File.exist? fname
  display_proc_stat fname
end
