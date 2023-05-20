#!/usr/bin/env ruby
# human-readable units for kb mb gb tg pb

def human_size(num)
  code = [ '', 'K', 'M', 'G', 'T', 'P']
  carry = 0
  dec = ''
  loop do
    rem = ((num % 1024) / 102.4).round
    n = num / 1024

    break if n < 1

    if rem > 0
      carry = 1
      dec = ".#{rem}"
    end
    code.shift
    num = n
  end

  if num > 10
    num += carry
    dec = ''
  end

  "#{num}#{dec}#{code.shift}"
end

ARGV.each { |arg| puts "HUMAN: " + human_size(arg.to_i) }
