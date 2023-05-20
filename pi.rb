#!/usr/bin/env ruby
# calculate Pi to specified precision

def calc_pi(num_recs)
  width = 1.0 / num_recs
  sum = 0.0

  num_recs.to_i.times do |i|
    mid = (i + 0.5) * width
    height = 4.0/(1.0 + mid*mid)
    sum += height
  end

  width * sum
end

if __FILE__ == $0
  num_recs = (ARGV.count > 0) ? ARGV.pop : 1000

  puts "PI for #{num_recs} precision: #{calc_pi(num_recs.to_f)}"
end
