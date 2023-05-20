#!/usr/bin/env ruby
# :title: Bgo::Changeset
=begin rdoc
BGO Changeset objects

Copyright 2011 Thoughtgang <http://www.thoughtgang.org>
=end

require 'rexml/document'
require 'rubygems'
require 'json'

module Bgo

=begin rdoc
Changeset for a Bgo::Map object.

This includes byte patches to Map#image and Address objects defined for this
Changeset.
=end
  class MapChangeset

=begin rdoc
=end
    attr_reader :ident

=begin rdoc
Hash of vma->Fixnum objects
=end
    attr_reader :changed_bytes


=begin rdoc
Comment for this changeset
=end
    attr_accessor :comment

=begin rdoc
The is_empty parameter determines whether this is the empty changeset.

An empty changeset represents the base image of the Map: it may have
addresses defined, but cannot be patched.
=end
    def initialize(ident, comment='', is_empty=false)
      @ident = ident
      @comment = comment
      @changed_bytes = {}
      @addresses = {}                 # Hash of vma->Address objects
      @is_empty_changeset = is_empty
    end

=begin rdoc
Returns false if this is the empty changeset, true otherwise.
=end
    def patchable?
      not @is_empty_changeset
    end

=begin rdoc
Patch bytes in the changeset. This applies the bytes in the String 'bytes' to
the changeset starting at the specified VMA. Existing changes for
affected VMAs will be overwritten.

Note: This returns false if the changeset cannot it not patchable.
=end
    def patch_bytes(vma, bytes)
      return false if not patchable?
      bytes.length.times { |i| @changed_bytes[vma+i] = bytes[i] }
      true
    end

=begin rdoc
This stores the Address object 'addr' at the specified VMA. It does not check
if the address already exists.
=end
    def add_address(vma, addr)
      @addresses[vma] = addr
    end

=begin rdoc
Return hash of Address objects. This can be overridden by child classes
(e.g. Git::MapChangeset) to provide an alternate implementation.
=end
    def address_hash
      @addresses.dup
    end

=begin rdoc
Return the Address object for the specified VMA. This can be overridden by 
child classes (e.g. Git::MapChangeset) to provide an alternate implementation.
=end
    def address(vma)
      @addresses[vma]
    end

=begin rdoc
List Address objects in MapChangeset
=end
    def addresses(ident_only=false, &block)
      list = []
      @addresses.values.sort_by { |a| a.vma }.each do |addr|
        a = ident_only ? addr.vma : addr
        yield a if block_given?
        list << a
      end
      list
    end

    # ----------------------------------------------------------------------
    def to_s
      # TODO
      super
    end

    def inspect
      # TODO
      super
    end

    # ----------------------------------------------------------------------

    XML_IDENT_ELEM='ident'
    XML_ADDRS_ELEM='addresses'
    XML_BYTES_ELEM='changes'
    XML_BYTE_ELEM='byte'
    XML_VMA_ELEM='vma'
    XML_VAL_ELEM='value'
    XML_CMT_ELEM='comment'

    def to_xml
      root = REXML::Element.new(self.class.name.split('::').last)

      el = root.add_attribute(XML_IDENT_ELEM,self.ident)

      el = root.add_element(XML_ADDRS_ELEM)
      addresses.each { |a| el.add_element(a.to_xml) }

      el = root.add_element(XML_BYTES_ELEM)
      changed_bytes.each do |vma, val|
        b_el = el.add_element(XML_BYTE_ELEM)
        b_el.add_attribute(XML_VMA_ELEM, "%X" % vma)
        b_el.add_attribute(XML_VAL_ELEM, "%X" % val)
      end

      el = root.add_element(XML_CMT_ELEM)
      el.add_element(comment) if comment && (! comment.empty?)

      root
    end

    def to_h
      {
        :ident => self.ident,
        :comment => self.comment
      }
    end

    def to_json(*a)
      {
        'json_class'  => self.class.name,
        'data'        => self.to_h
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

  end

end
