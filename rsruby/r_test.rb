#!/usr/bin/env ruby

require 'rubygems'
require 'rsruby'
#sudo rvm all do gem install rsruby -- --with-R-home=/usr/lib/R --with-R-include=/usr/share/R/include

# TODO: platform-detect
R_HOME = '/usr/lib/R'
#R_GRAPHICS_FIX = 'X11.options(type="Xlib")'
#R_GRAPHICS_FIX = 'graphics.off(); X11.options(type="nbcairo")'
R_GRAPHICS_FIX = 'graphics.off(); X11.options(type="Xlib")'

ENV['R_HOME'] ||= R_HOME

theR = RSRuby.instance
theR.eval_R(R_GRAPHICS_FIX) if R_GRAPHICS_FIX

theR.plot(theR.rnorm(1000), :type => 'l')
gets

#d = theR.rnorm(1000)
#l = theR.range(-4,4,d)
#theR.plot(d, :type => 'l')
#theR.png "/tmp/plot.png"
#theR.par(:bg => "cornsilk")
#theR.hist(d, :range => l, :col => "lavender", :main => "My Plot")
#theR.eval_R("dev.off()")  #required for png output
#g = File.open("/tmp/plot.png", "rb") {|@f| @f.read}
