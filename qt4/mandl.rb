#!/usr/bin/env ruby1.8
# Usage: mandl.rb x y size threshold
# where X and Y are the real and imaginary parts of C in the eqn Z = Z^2 + C,
# size is the magnification, and threshold is how many iterations to attempt
# Defaults: -2.0 -1.0 3.0 100

require 'Qt4'
 
WIN_X = 400
WIN_Y = 400

class MandleData
  attr_reader :origin_x, :origin_y
  attr_reader :size, :threshold

  def initialize( x, y, size, threshold=100 )
    @origin_x = x
    @origin_y = y
    @size = size
    @threshold = threshold
  end

  def color?(x, y)
    ca = @origin_x + ((x*@size)/WIN_X)
    cb = @origin_y + ((y*@size)/WIN_Y)
    zx = zy = 0
    count = 0
    while (count < @threshold) do
      count += 1
      xx = zx * zx 
      yy = zy * zy
      zy = ((2 * zx) * zy) + cb
      zx = xx - yy + ca
      break if xx + yy > 4
    end

    count >= @threshold
  end
end

class MandleTimer < Qt::Object
  attr_reader :id, :obj

  def initialize(obj)
      super(nil)
      @obj = obj
      @id = startTimer(10)
  end

  def timerEvent(event)
    @obj.timerEvent
  end

  def stopTimer
    killTimer @id
  end
end

class MandleWin < Qt::Widget
  attr_reader :timer
  attr_reader :scene, :view
  attr_reader :row
  attr_reader :data

  def initialize(data, parent=nil)
    super parent
    @data = data
    @row = 0

    setWindowTitle("Mandle")

    @scene = Qt::GraphicsScene.new(0, 0, 400, 400)
    @view = Qt::GraphicsView.new(@scene, self)

    @view.renderHint = Qt::Painter::Antialiasing
    @scene.backgroundBrush = Qt::white
    @scene.foregroundBrush = Qt::black

    @timer = MandleTimer.new(self)

    @view.show
  end

  def keyPressEvent(event)
    case event.key
      when Qt::Key_Q:
        $qApp.quit()
        return
    end
  end

  def timerEvent
    if @row == WIN_Y
      @timer.stopTimer
      return
    end
    WIN_X.times do |x|
      @scene.addItem( Qt::GraphicsEllipseItem.new(x,@row,1,1) ) \
             if @data.color?(x, @row)
    end
    @row += 1
  end

end

class MandleApp < Qt::Application

  def initialize( args )
    super(args)
    initialize_ui(args)
  end

  def initialize_ui(args)
    start_x = args.count > 0 ? args.pop.to_f : -2.0
    start_y = args.count > 0 ? args.pop.to_f : -1.0
    size = args.count > 0 ? args.pop.to_f : 3.0
    threshold = args.count > 0 ? args.pop.to_i : 100

    w = MandleWin.new( MandleData.new(start_x, start_y, size, threshold) )

    w.show()
  end
end

if __FILE__ == $0
  app = MandleApp.new(ARGV)
  app.exec()
end
