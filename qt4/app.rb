#!/usr/bin/env ruby1.8

require 'Qt4'
 
class ElderWidget < Qt::Widget
  def initialize(parent = nil)
    super parent
    resize(200, 120)
    btn = Qt::PushButton.new('Nyarlathotep', self)
    btn.font = Qt::Font.new('Times', 18, Qt::Font::Bold)
    btn.setGeometry(10, 40, 180, 40)
    Qt::Object.connect(btn, SIGNAL('clicked()'), $qApp, SLOT('quit()'))
  end
end

class ElderApplication < Qt::Application

  def initialize( args )
    super(args)
    initialize_ui
  end

  def initialize_ui()
    w = ElderWidget.new()
    w.show()
  end
end

if __FILE__ == $0
  app = ElderApplication.new(ARGV)
  app.exec()
end
