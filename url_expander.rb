#!/usr/bin/env ruby
# expand a shortened URL by following all redirects
require 'net/http'

def expand_url(str)
  while(hdr=Net::HTTP.get_response(URI(str)) and hdr.code[0] == '3')
    str = hdr['location']
  end
  puts str
end

if __FILE__ == $0
  ARGV.each do |arg|
    puts expand_url arg
  end
end
