=begin
**
** commandline.rb
** 03/JUN/2007
** ETD-Software
**  - Daniel Martin Gomez <etd[-at-]nomejortu.com>
**
** Desc:
**   Qt custom widget that behaves as a standard command line. It keeps a 
** buffer of commands that can be accessed by pressing Up and Down keys.
**
** Version:
**  v1.0 [03/Jun/2007]: first released
**
** This file may be used under the terms of the GNU General Public
** License version 2.0 as published by the Free Software Foundation
** and appearing in the file LICENSE.GPL included in the packaging of
** this file.  Please review the following information to ensure GNU
** General Public Licensing requirements will be met:
** http://www.trolltech.com/products/qt/opensource.html
**
=end

require 'Qt4'

class CommandLine < Qt::LineEdit
  slots 'clear_history()'

  def initialize(parent=nil)
    super(parent)
    #initialize internal history buffer
    @history = []
    @pointer = 0
  end

  #override some event handlers
  def keyPressEvent(event)

    case event.key 
      when Qt::Key_Up:
        if ((@history.size > 0) && (@pointer >= 0) )
          if (@pointer == @history.size)
            @history << self.text 
          end
          @pointer -= 1 if @pointer > 0
          self.text = @history[@pointer]
        end
        return

      when Qt::Key_Down:
        if ((@history.size > 0) && (@pointer < @history.size) )
          @pointer += 1 if @pointer < @history.size - 1
          self.text = @history[@pointer]
        end
        return

      #add a new element to the local @history
      when Qt::Key_Return:

        #keep an eye on the last entry to avoid empty entries in the list
        if ((@history.size > 0) && (@history.last.strip.size == 0) )
          @history.pop
        end

        if self.text.strip.size > 0
          @history << self.text
          @pointer = @history.size
          self.clear
        else
          return
        end
    end

    super
  end


  def clear_history()
    @history.clear
  end

  def last_command()
    @history.last
  end
end

if $0 == __FILE__
    a = Qt::Application.new(ARGV)
    w = CommandLine.new
    w.show
    a.exec
end
