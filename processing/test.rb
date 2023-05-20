#!/usr/bin/env jruby

require 'rubygems'
require 'ruby-processing'

class FollowCursor < Processing::App
  def setup
    size 800, 600
    smooth
  end

  def draw
    background 1
    translate( mouse_x, mouse_y )
    sphere 20   
  end 
end  

Bubble.new(*values) 
FollowCursor.new(:width => 200, :height => 200, :title => "Follow The Cursor!") 
