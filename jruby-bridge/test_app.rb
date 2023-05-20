#!/usr/bin/env ruby
# Test application for Tika JRuby-Bridge

require 'tika_service'

Tika::Service.start
begin
  tika = Tika::Service.connect
  if tika
    ARGV.each { |x| File.open(x, 'rb') {|f| puts tika.parse(f.read).inspect} }
  end
ensure
  Tika::Service.disconnect
  Tika::Service.stop
end
