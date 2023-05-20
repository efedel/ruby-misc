#!/usr/bin/env jruby                                                            

require 'rubygems'
require 'ruby-processing'

class ImageViewer < Processing::App
  def initialize(path, *args)
    @image_file = path
    super *args
  end

  def setup
    @img = loadImage(@image_file);
    size(@img.width, @img.height);
    smooth();
    #save_frame "output.png"
  end

  def draw
    image(@img, 0, 0);
    filter(BLUR, 2);
  end
end

if __FILE__ == $0
  ImageViewer.new ARGV.first, :width => 360, :height => 300, :title => "Blurrr"
end
