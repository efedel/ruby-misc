#!/usr/bin/env jruby                                                            

require 'rubygems'
require 'ruby-processing'

class Nautilus < Processing::App
  A = 0.8  # pitch constant
  B = 1.4  # radius constant
  def initialize(data, *args)
    @data_points = data
    super *args
  end

  def setup
    translate 230, 120 # offset x and y from origin
    rotate QUARTER_PI + HALF_PI # initial rotation
    smooth
    background 0
    stroke_weight 1
    stroke 255
    for z in 8 .. 40 do # draw the radial lines first (it looks nicer)
      line(get_x(z*A), get_y(z*A), get_x((z-8)*A), get_y((z-8)*A))
    end
    no_fill
    begin_shape # begin spiral 'shell' shape
    stroke_weight 4
    stroke 255, 0, 0
    for i in 0 .. 40 do
      vertex(get_x(i*A), get_y(i*A))
    end
    end_shape
    #save_frame "nautilus.png"
  end
  def get_x theta
    A*Math.cos(theta)*Math.exp(theta/Math.tan(B))
  end
   def get_y theta
    A*Math.sin(theta)*Math.exp(theta/Math.tan(B))
  end    
end

if __FILE__ == $0
  Nautilus.new ARGV, :width => 360, :height => 300, :title => "Approximate Nautilus"
end
