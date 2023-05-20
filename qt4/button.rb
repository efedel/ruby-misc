#!/usr/bin/env ruby1.8

require 'Qt4'
 
app = Qt::Application.new(ARGV)
 
w = Qt::Widget.new()
w.resize(200, 120)
 
btn = Qt::PushButton.new('Nyarlathotep', w)
btn.font = Qt::Font.new('Times', 18, Qt::Font::Bold)
btn.setGeometry(10, 40, 180, 40)
Qt::Object.connect(btn, SIGNAL('clicked()'), app, SLOT('quit()'))
 
w.show()
 
app.exec()
