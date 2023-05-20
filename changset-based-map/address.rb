#!/usr/bin/env ruby
# :title: Bgo::Address
=begin rdoc
BGO Address object

Copyright 2010 Thoughtgang <http://www.thoughtgang.org>

An address can contain structured data, an instruction, or raw bytes.
=end

require 'rexml/document'
require 'rubygems'
require 'json'

require 'bgo/instruction'

module Bgo

=begin rdoc
A definition of an address in an Image (e.g. the contents of a File or
Process).
Note that the contents of the address determine its properties, e.g. the
type of address (code or data), what it references, etc.
TODO: handle references TO address.

This is the base class for Address objects. It also serves as an in-memory
object when there is no backing store.
=end
  class Address

=begin rdoc
The address contains an Instruction object.
=end
    CONTENTS_CODE = :code
=begin rdoc
The address contains a data object (pointer, variable, etc)
=end
    CONTENTS_DATA = :data
=begin rdoc
The address contains no content object, i.e. just raw bytes.
=end
    CONTENTS_UNK  = :unknown
=begin rdoc
An Image or VirtualImage (.bss) containing the bytes
=end
    attr_reader :image
=begin rdoc
Offset of address in image.
=end
    attr_reader :offset
=begin rdoc
Load address (VMA in process, offset in file).
=end
    attr_reader :vma
=begin rdoc
Size (in bytes) of address.
=end
    attr_reader :size

=begin rdoc
A user-supplied comment
=end
    attr_accessor :comment

=begin rdoc
Contents of Address (e.g. an Instruction object).
=end
    attr_reader :contents_obj

=begin rdoc
Names (symbols) applied to the address or its contents.

This is a hash of id-to-name mappings:
  :self => name of address or nil
  0 => name to use in place of first operand
  1 => name to use in place of second operand
...etc.

Storing the names in-address (and applying them to operands) removes the
need for explicit scoping.
=end
# In Git: if n.to_i.to_s == n, name = n else name = n.to_sym
    attr_reader :names

=begin rdoc
An Array of Reference objects.
=end
    attr_reader :references

    # ----------------------------------------------------------------------
    def initialize( image, offset, size, vma=nil, contents=nil, comment='' )
      @image = image
      @offset = offset
      @size = size
      @vma = vma ? vma : offset
      @contents_obj = contents
      @comment = comment
      @names = {}
      @references = []
    end

    alias :ident :vma

=begin rdoc
Convenience function that returns the load address (VMA) of the last byte in
the Address. An Address is a sequence of bytes from vma to end_vma.
=end
    def end_vma
      vma + size - 1
    end

=begin rdoc
Return String of (binary) bytes for Address. This uses @container#[]
=end
    def bytes
      image[offset,size]
    end

=begin rdoc
Return contents of Address, or bytes in address if Contents object has not
been set.
=end
    def contents
      # TODO: return bytes as string?
      contents_obj ? contents_obj : bytes
    end

    def contents=(obj)
      @contents_obj = obj
    end

=begin rdoc
Nature of contents: Code, Data, or Unknown.
This saves an awkward comparison on contents.class for what is a commonly-performed operation.
=end
    def content_type
      return CONTENTS_UNK if not contents_obj
      (contents_obj.kind_of? Bgo::Instruction) ? CONTENTS_CODE : CONTENTS_DATA
    end

=begin rdoc
Return true if argument is a valid content type.
=end
    def self.valid_content_type?(str)
      sym = str.to_sym
      [CONTENTS_UNK, CONTENTS_CODE, CONTENTS_DATA].include? sym
    end

=begin rdoc
Return true if Address contains an Instruction object.
=end
    def code?
      content_type == CONTENTS_CODE
    end

=begin rdoc
Return true if Address is not code.
=end
    def data?
      content_type != CONTENTS_CODE
    end

    def name(ident=:self)
      self.names[ident]
    end

    def set_name(ident, str)
      # Note: git impl overrides this method, so '@' must be used, not 'self.'
      @names[ident] = str
    end

    def name=(str)
      add_name(:self, str)
    end

    def add_ref_to(vma, access='r--')
      # ref = ReferenceToAddress.new(vma, access)
      # self.references << ref
      # add_ref_from ?
    end

    def add_ref_from(vma, access='r--')
      # ditto
    end
    
    # ----------------------------------------------------------------------
  
=begin rdoc
Return (and/or yield) a contiguous list of Address objects for the specified
memory region. 
addrs is a list of Address objects defined for that region.
image is the Image object containing the bytes in the memory region.
load_addr is the VMA of the Image (vma for Map, or 0 for Sections).
offset is the offset into Image to start the region at.
length is the maxium size of the region

This is used by Section and Map to provide contiguous lists of all Addresses
they contain.
=end

    def self.address_space(addrs, image, load_addr, offset=0, length=0)
      list = []
      length = (image.size - offset) if length == 0
      prev_vma = load_addr + offset
      prev_size = 0

      addrs.each do |a|
        prev_end = prev_vma + prev_size
        if prev_end < a.vma
          # create new address object 
          addr = Bgo::Address.new(image, prev_end - load_addr, a.vma - prev_end,
                                  prev_end)
          yield addr if block_given?
          list << addr
        end

        yield a if block_given?
        list << a
        prev_vma = a.vma; prev_size = a.size
      end

      # handle edge cases
      if list.empty?
        # handle empty list
        addr = Bgo::Address.new(image, offset, length, load_addr)
        yield addr if block_given?
        list << addr
      else 
        # handle empty space at end of section
        last_vma = list.last.vma + list.last.size
        max_vma = load_addr + offset + length
        if last_vma < max_vma
          addr = Bgo::Address.new(image, last_vma - load_addr, 
                                  max_vma - last_vma, last_vma)
          yield addr if block_given?
          list << addr
        end
      end
      list
    end

    # ----------------------------------------------------------------------
    def to_s
      # TODO: contents-type, flags, etc
      "%08X (%d bytes)" % [vma, size]
    end

    def inspect
      # TODO: bytes or contents
      "%08X %s, %d bytes" % [vma, content_type.to_s, size]
    end

    def to_h
      { :size => @size,
        :vma => @vma,
        :content_type => content_type,
        :bytes => bytes,
        :content => contents
      }
    end

    # ----------------------------------------------------------------------
    # Serialization

    XML_VMA_ELEM='vma'
    XML_OFFSET_ELEM='offset'
    XML_SIZE_ELEM='size'
    XML_IMAGE_ELEM='image'
    XML_BYTES_ELEM='bytes'
    XML_CMT_ELEM='comment'
    XML_CONTENTS_ELEM='contents'

    def to_xml
      root = REXML::Element.new(self.class.name.split('::').last)

      root.add_attribute( XML_VMA_ELEM, "%d" % self.size )
      root.add_attribute( XML_OFFSET_ELEM, "%X" % self.offset )
      root.add_attribute( XML_SIZE_ELEM, "%X" % self.vma )
      root.add_attribute( XML_IMAGE_ELEM, self.image.ident )

      el = root.add_element( XML_BYTES_ELEM )
      el.add_text( self.bytes.map{ |x| "%02X" % x }.join(' ') ) if self.bytes

      el = root.add_element( XML_CONTENTS_ELEM )
      if contents.respond_to? :to_xml
        el.add_element(contents.to_xml)
      else
        el.add_text(contents.to_s)
      end

      el = root.add_element( XML_CMT_ELEM )
      el.add_text(comment) if comment && (! comment.empty?)

      root
    end

    def to_json(*a)
      {
          'json_class'   => self.class.name, 
          'data'         => self.to_h
      }.to_json(*a)
    end

    def self.from_xml(root)
      return if not root
      @root_items.each do |item|
      #  TODO!
      #  item.from_xml( root )
      end
    end
    
    def self.from_json(str)
      begin
        JSON.parse str
      rescue
        $stderr.puts "Unable to parse: #{str.inspect}"
      end
    end

=begin rdoc
JSON callback to create a ModelItem object from a JSON string.
=end
    def self.json_create(o)
      # Fix hash keys that were converted to Strings by JSON
      self.from_hash(o['data'].inject({}) { |h,(k,v)| h[k.to_sym] = v; h })
    end

    def self.from_hash(hash)
        # TODO! requires CTOR support Hash, or a fill(hash) method
        #self.new(hash[:id], hash[:create_date], hash)
    end


  protected
=begin rdoc
Instruction, object, structure/variable or nil.
=end
    attr_accessor :contents_obj

  end

=begin rdoc
=end
  class AddressRef
    # TODO: reference type? e.g. read, write, exec
    attr_reader :map, :vma, :changset

    def initialize(map, vma, cs=map.current_changeset)
      @map = map
      @vma = vma
      @changeset = cs
    end

=begin rdoc
=end
    def address
      map.address(vma, changeset)
    end
  end

end
