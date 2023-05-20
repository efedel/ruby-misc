#!/usr/bin/env ruby

require 'Qt4'

class DumbModelItem < Qt::StandardItem
  def initialize(title, path, data=nil)
    icon = \
      Qt::Icon.new(":/trolltech/styles/commonstyle/images/viewdetailed-32.png")
    super icon, title
    setData(Qt::Variant.new(title), Qt::UserRole + 1)
    setData(Qt::Variant.new(path), Qt::UserRole + 2)
    setData(Qt::Variant.new(data ? data : ''), Qt::UserRole + 3)
  end

  def clone
    self.class.new( data(Qt::UserRole + 1).toString, 
                    data(Qt::UserRole + 2).toString,
                    data(Qt::UserRole + 3).toString )
  end

  def to_s
    "#{data(Qt::UserRole + 2).toString} TITLE '#{data(Qt::UserRole + 1).toString}' DATA '#{data(Qt::UserRole + 3).toString}'"
  end
end

class DumbModel < Qt::StandardItemModel

  def initialize
    super
    self.setItemPrototype( DumbModelItem.new('PROTOTYPE', 'NIL', nil) )
    fill_model
  end

  def fill_model
    @root = self.invisibleRootItem
    self.beginInsertRows(indexFromItem(@root), 0, 2)
    items = {}

    [ { :title => 'A', :path => '/A', :data => '1234567890' },
      { :title => 'B', :path => '/B', :data => 'BBBBBBBBBB' },
      { :title => 'C', :path => '/C', :data => 'CCCCCCCCCC' } ].each do |h|
      item = DumbModelItem.new(h[:title], h[:path], h[:data]) 
      @root.appendRow( item )
      items[h[:path]] = item
      end
    [ { :title => '1', :path => '/A/1', :data => 'AAAA1111' },
      { :title => '2', :path => '/A/2', :data => 'AAAA2222' },
      { :title => '3', :path => '/A/3', :data => 'AAAA3333' },
      { :title => '4', :path => '/A/4', :data => 'AAAA4444' } ].each do |h|
      item = DumbModelItem.new(h[:title], h[:path], h[:data]) 
      items['/A'].appendRow( item )
      items[h[:path]] = item
      end
    [ { :title => '1', :path => '/B/1', :data => 'BBBB1111' } ].each do |h|
      item = DumbModelItem.new(h[:title], h[:path], h[:data]) 
      items['/B'].appendRow( item )
      items[h[:path]] = item
      end
    [ { :title => '1', :path => '/C/1', :data => 'CCCC1111' } ].each do |h|
      item = DumbModelItem.new(h[:title], h[:path], h[:data]) 
      items['/C'].appendRow( item )
      items[h[:path]] = item
      end
    [ { :title => 'a', :path => '/A/1/a', :data => 'AA11aa' },
      { :title => 'b', :path => '/A/1/b', :data => 'AA11bb' } ].each do |h|
      item = DumbModelItem.new(h[:title], h[:path], h[:data]) 
      items['/A/1'].appendRow( item )
      items[h[:path]] = item
      end
    self.endInsertRows
  end
end
 
class DumbTreeView < Qt::TreeView
  slots 'selectionChanged(const QItemSelection &, const QItemSelection &)'

  def selectionChanged( sel, prev )
    return if ! sel
    sel.indexes.each do |idx|
      item = model.itemFromIndex(idx) if idx
      puts item.to_s
    end
  end
end

class DumbWin < Qt::MainWindow
  def initialize(the_model, parent=nil)
    super parent

    @tree_view = DumbTreeView.new self
    @tree_view.sizePolicy = Qt::SizePolicy::Preferred
    @tree_view.header.hide
    @tree_view.setAlternatingRowColors true
    @tree_view.contextMenuPolicy = Qt::CustomContextMenu
    @tree_view.selectionBehavior = Qt::AbstractItemView::SelectRows
    @tree_view.selectionMode = Qt::AbstractItemView::ExtendedSelection
    @tree_view.editTriggers = Qt::AbstractItemView::DoubleClicked | \
                            Qt::AbstractItemView::EditKeyPressed
    @tree_view.headerHidden = true
    @tree_view.acceptDrops = true
    @tree_view.dragEnabled = true
    @tree_view.showDropIndicator = true
    #@tree_view.dragDropMode = Qt::AbstractItemView::DragDrop
    @tree_view.dragDropMode = Qt::AbstractItemView::InternalMove

    setCentralWidget( @tree_view )
    @tree_view.setModel the_model
  end

end

class DumbApplication < Qt::Application

  def initialize( args )
    super(args)
    @model = DumbModel.new
    initialize_ui
  end

  def initialize_ui()
    w = DumbWin.new(@model)
    w.show()
  end
end

if __FILE__ == $0
  app = DumbApplication.new(ARGV)
  app.exec()
end
