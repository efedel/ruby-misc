#!/usr/bin/env ruby
# :title: Bgo::Map
=begin rdoc
BGO Map object

Copyright 2010 Thoughtgang <http://www.thoughtgang.org>
=end  

# TODO: Map#address needs to be more complete
# TODO: Delete Address

require 'bgo/address'
require 'bgo/byte_container'
require 'bgo/changeset'

require 'rexml/document'
require 'rubygems'
require 'json'

module Bgo

=begin rdoc
A Memory Mapping. This maps a portion of an Image into a Process address space.

This is the base class for Map objects. It also serves as an in-memory object
when there is no backing store.
=end
  class Map < Bgo::ByteContainer

=begin rdoc
Exception raised when an Address is added that overlaps an existing 
Address object in the Map.

This can occur for duplicate Address objects, or for Address objects that
contain addresses already allocated to another Address object.

This exception can be avoided by calling Map.#exist? before calling
Map#add_address. To force the new Address to be added, delete the existing
Address object, or create a new changeset via Map#add_changeset.
=end
    class AddressExists < RuntimeError
    end

=begin rdoc
Exception raised when a request (e.g. Map#add_address) would exceed the Map
boundaries.
=end
    class BoundsExceeded < RuntimeError
    end

=begin rdoc
ID (index) of the current changeset for the Map.
=end
    attr_reader :current_changeset

=begin rdoc
List of flags for mapped memory (e.g. RWX).
=end
    attr_accessor :flags

=begin rdoc
The value from Process#arch_info. This just makes Map a standalone object.
=end
    attr_accessor :arch_info

=begin rdoc
A user-supplied comment.
=end
    attr_accessor :comment


    FLAG_READ = 'r'
    FLAG_WRITE = 'w'
    FLAG_EXEC = 'x'
    FLAGS = [ FLAG_READ, FLAG_WRITE, FLAG_EXEC ]
    DEFAULT_FLAGS = [ FLAG_READ, FLAG_WRITE ]

=begin rdoc
Instantiate a Map object
=end
    def initialize( start_addr, image, offset=0, size=nil, flags=DEFAULT_FLAGS,
                    arch_info=nil, comment='' )
      super image, start_addr, offset, size, arch_info
      @flags = flags.dup
      @comment = comment
      @arch_info = arch_info
      @changesets = [ MapChangeset.new(0, 'Base image', true) ]
      @current_changeset = 0
    end

=begin rdoc
Strip invalid flags from flags array
=end
    def self.validate_flags( flags )
      return [] if not flags
      flags.reject { |f| not FLAGS.include? f }
    end

    alias :ident :start_addr

=begin rdoc
Return last valid address in Map.
=end
    def end_addr
      self.start_addr + self.size - 1
    end

=begin rdoc
Return true if mapped memory is executable.
=end
    def executable?
      flags.include? FLAG_EXEC
    end

=begin rdoc
Return true if mapped memory is readable.
=end
    def readable?
      flags.include? FLAG_READ
    end

=begin rdoc
Return true if mapped memory is writeable.
=end
    def writeable?
      flags.include? FLAG_WRITE
    end

# ----------------------------------------------------------------------
# Changesets

=begin rdoc
Return the current changeset object.
=end
    def changeset
      changeset_obj(current_changeset)
    end

=begin rdoc
Set the current changeset to specified ident. This raises an exception if the 
specified changeset does not exist.
=end
    def changeset=(val)
      raise "No such changeset" if (val < 0 || val >= changesets.count)
      @current_changeset = val
    end

    alias :current_changeset= :changeset=

=begin rdoc
Return an array of the MapChangeset objects in the Map. The index of a 
changeset in the array is its id. Note that index 0 if the empty changeset: 
no patches can be added to it.
=end
    def changesets(ident_only=false, &block)
      list = []
      @changesets.each do |ident, cset|
        cs = ident_only ? ident : cset
        yield cs if block_given?
        list << cs
      end
      list
    end

=begin rdoc
Add a new changeset to Map. The new changeset becomes the current changeset.
Returns the new changeset (Hash of VMA->byte).
=end
    def add_changeset(comment='')
      ident = @changesets.count 
      @changesets << MapChangeset.new(ident, comment)
      self.changeset = ident
      @changesets[ident]
    end

=begin rdoc
Patch bytes in current changeset. This applies the bytes in the String 'bytes'
to the current changeset starting at the specified VMA.
=end
    def patch_bytes(vma, bytes)
      cs = changeset
      cs = add_changeset('Autocreated on first patch') if (not cs.patchable?)
      cs.patch_bytes(vma, bytes)
      cs
    end

=begin rdoc
Return an Image object representing the contents of the Map at the specified
changeset.
Note that this is an in-memory Image object generated on the fly *unless*
the changeset is 0 (i.e. the base Image for the Map).
=end
    def image(change=current_changeset)
      patched_image(super(), change)
    end

# ----------------------------------------------------------------------
# Addresses

=begin rdoc
Return true if an Address object exists for vma. This checks that whether any
defined Address object contains vma. If an Address object exists at offset
0x100 with a size of 4 bytes, then Map#exist? will return true for 0x100,
0x101, 0x102, and 0x103.

Note: This only checks Address objects defined in the specified changeset
unless recurse is true.
=end
    def exist?(vma, recurse=true, change=current_changeset)
      range_exist? vma, 1, recurse, change
    end

=begin rdoc
Return true if the range of addresses exists in any defined Address object(s)
in the specified changeset.
If recurse is true, this also checks all changesets lower than the specified
changeset.
=end
    def range_exist?(vma, size, recurse=true, change=current_changeset)
      addrs = recurse ? address_range(vma, size, change, false) :
                        address_hash(change).values.reject do |a|
        a.end_vma < vma || a.vma >= vma + size 
      end

      addrs.count > 0
    end

=begin rdoc
List all Address objects defined in Map.

By default, this invokes address_range on the specified changeset and
returns a list of all valid Address objects. This means that Address objects
defined in previous changesets will be included if their addresses were not
redefined by a later changeset.

To restrict the list of Addresses to those defined in the specified changeset,
set recurse to false.
=end
    def addresses(ident_only=false, recurse=true, change=current_changeset,
                  &block)
      addrs = recurse ? address_range(start_addr, size, change, true) :
                        address_hash(change).values
      list = []
      addrs.each do |addr|
        a = ident_only ? addr.vma : addr
        yield addr if block_given?
        list << addr
      end
      list
    end

=begin rdoc
Instantiate Address object at VMA in Map.
=end
    def address(vma, change=current_changeset)
      # TODO: find address object in all changesets
      address_hash(change)[vma]
    end

=begin rdoc
Define Address object at VMA in Map.
=end
    def add_address(vma, len, comment='', change=current_changeset)
      addr_offset = vma - start_addr
      raise BoundsExceeded if (addr_offset < 0 || addr_offset + len > size)
      #NOTE: this really slows things down
      raise AddressExists if range_exist?(vma, len, false)

      addr = Bgo::Address.new( image, addr_offset, len, vma, comment)
      changeset_obj(change).add_address(vma, addr)
      addr
    end

=begin rdoc
strict : if the start or end addr is inside an Address object that extends 
outside the specified range, then include that Address object in the output
if strict is true; otherwise, create dummy address objects for the bytes in
the range that are inside the Address object.

Note: this does not only returns all valid Address objects. Use 
contiguous_addresses to get a complete address range with virtual Address
objects filling all gaps.
=end
    def address_range(start_vma, len, change=current_changeset, strict=false)

      # Note: this method just wraps build_address_range to hide the
      #       dual strict variables needed during recursion
      build_address_range(start_vma, len, change, strict, strict)
    end


=begin rdoc
Return (and/or yield) a contiguous list of Address objects in the Map.
Gaps between defined Address objects will be filled with an Address object
that spans the gap; this Address object is not stored in the Project.
=end
    def contiguous_addresses(change=current_changeset, &block)
      Bgo::Address.address_space( addresses(false, true, change), image, 
                                  start_addr, offset, size, &block )
    end

=begin rdoc
Return (and/or yield) a contiguous list of Address objects in the specified
range of the Map.
See. Map#contiguous_addresses.
=end
    def contiguous_range(start_vma, len, change=current_changeset, strict=false,
                         &block)
      Bgo::Address.address_space(address_range(start_vma, len, change, strict), 
                                 image, start_addr, offset, size, &block)
    end


=begin rdoc
Returns an Array of Address objects in Range.
=end
    def [](*args)
      # defaults to current changeset
      raise NotImplementedError
    end

# ----------------------------------------------------------------------
    def to_s
      "Map 0x%X" % start_addr
    end

    def inspect
      vma = "0x%X" % start_addr
      "Map #{vma}: #{size} bytes (#{comment})"
    end

# ----------------------------------------------------------------------
    # Serialization

    XML_START_ELEM='start vma'
    XML_IMAGE_ELEM='image'
    XML_OFFSET_ELEM='image offset'
    XML_SIZE_ELEM='size'
    XML_FLAGS_ELEM='flags'
    XML_CMT_ELEM='comment'
    XML_CS_ELEM='changesets'

    def to_xml
      root = REXML::Element.new(self.class.name.split('::').last)

      el = root.add_attribute(XML_START_ELEM, "0x%X" % self.start_addr)
      el = root.add_attribute(XML_IMAGE_ELEM, self.image.ident.to_s)
      el = root.add_attribute(XML_OFFSET_ELEM, "0x%X" % self.offset)
      el = root.add_attribute(XML_SIZE_ELEM, "0x%X" % self.size)

      el = root.add_element(XML_FLAGS_ELEM)
      flags.each { |f| el.add_attribute(f, true) }

      el = root.add_element(self.arch_info.to_xml) if self.arch_info

      el = root.add_element(XML_CS_ELEM)
      changesets.each { |cs| el.add_element(cs.to_xml) }

      el = root.add_element(XML_CMT_ELEM)
      el.add_element(comment) if comment && (! comment.empty?)

      root
    end

    def to_h
      {
        :start_addr => self.start_addr,
        :image => self.image,
        :offset => self.offset,
        :size => self.size,
        :flags => self.flags,
        :arch_info => self.arch_info,
        :changesets => self.changesets,
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


# ----------------------------------------------------------------------
    protected

=begin rdoc
Wrapper for MapChangeset#address_hash. This is used internally to obtain a
Hash of Address objects for lookup purposes (i.e. the Hash is not modified).
=end
    def address_hash(change)
      @changesets[change].address_hash
    end

=begin rdoc
Wrapper for internal use of @changesets. This allows child classes (e.g. 
Git#Map) to provide an alternate implementation.
=end
    def changeset_obj(change)
      @changesets[change]
    end

=begin rdoc
Backend for Map#address_range.
=end
    def build_address_range(start_vma, len, change, strict_start, strict_end)
      img = image(0)  # no need for patching; this is just a size check
      len = img.size if len > img.size
      addrs = []
      cs_addrs = address_hash(change)
      all_vmas = cs_addrs.keys.sort
      max_vma = start_vma + len - 1

      vma_list = build_vma_list(all_vmas, cs_addrs, start_vma, max_vma, 
                                strict_start, strict_end)

      addrs.concat fill_start_gap(all_vmas, cs_addrs, vma_list, start_vma, 
                                  change, strict_start)

      # ==================================================
      # Fill addrs with Address objects from this changeset
      vma_list.each do |curr_vma|

        # Is there a gap between previous Address object and this one?
        if addrs.last
          next_addr = addrs.last.vma + addrs.last.size

          if next_addr < curr_vma
            # ... if yes, then fill the gap based on the previous changeset
            # Note that this gap is ALWAYS strict
            addrs.concat build_address_range(next_addr, curr_vma - next_addr, 
                                 change - 1, true, true) unless change == 0
          end
        end

        # Do not add address if it extends beyond max_vma (unless !strict)
        a = cs_addrs[curr_vma]
        addrs << a if (not strict_end) || a.end_vma <= max_vma
      end

      addrs.concat fill_end_gap(addrs.last, start_vma, max_vma, change, 
                                strict_end)
      addrs
    end

=begin rdoc
Helper method for build_address_range. Generates a list of vmas to process.
=end
    def build_vma_list(all_vmas, cs_addrs, start_vma, max_vma, strict_start, 
                       strict_end)

      # Restrict vma_list to Addresses in requested range
      vma_list = all_vmas.reject do |vma| 
        vma < start_vma || cs_addrs[vma].end_vma > max_vma
      end

      # ==================================================
      # Include Addresses that extend beyond bounds 
      # Note: this is a 'principle of least surprise' feature. Unless strict,
      #       Address objects *containing" requested addresses are returned.

      # If first Address is > start_vma, add the preceding Address
      if not strict_start && (not vma_list.include? start_vma)

        # Find Address object that contains start_vma
        prev_vma = nil
        all_vmas.each do |v| 
          prev_vma = v if (v < start_vma && cs_addrs[v].end_vma >= start_vma)
        end
        vma_list.unshift( prev_vma ) if prev_vma
      end

      # ==================================================
      # If last Address is < max_vma, add the succeeding Address
      if not strict_end
        last_vma = vma_list.count > 0 ? cs_addrs[vma_list.last].end_vma : 
                                        start_vma

        # This is kind of tricky, as start_vma may equal max_vma when
        # vma_list is empty (e.g. during an end-fill)
        if (last_vma == start_vma) || last_vma < max_vma

          # Find Address object that contains max_vma
          next_vma = nil
          all_vmas.reverse.each do |v|
            next_vma = v if (v <= max_vma && cs_addrs[v].end_vma >= max_vma)
          end
          vma_list.push( next_vma ) if next_vma
        end

      end

      vma_list
    end

=begin rdoc
Helper method for build_address_range. Fills gap at start of address range
with contents of previous changesets.
=end
    def fill_start_gap(all_vmas, cs_addrs, vma_list, start_vma, change, 
                       strict_start)

      # Is there a gap between start_vma and the first Address object?
      return [] if (vma_list.count == 0 || vma_list.first <= start_vma ||
                    change == 0)

      # If start addr is inside an Address, then start *after* that Address
      idx = all_vmas.index(vma_list.first)
      prev_vma = all_vmas[idx-1]
      the_vma = (prev_vma && cs_addrs[prev_vma].end_vma >= start_vma) ?
                 cs_addrs[prev_vma].end_vma + 1 : start_vma

      # Fill the gap based on the previous changeset
      build_address_range(the_vma, vma_list.first - the_vma, change - 1, 
                          strict_start, true)
    end

=begin rdoc
Helper method for build_address_range. Fills gap at end of address range with
contents of previous changesets.
=end
    def fill_end_gap(last_addr, start_vma, max_vma, change, strict_end)
      # ==================================================
      # Is there a gap between the last Address object and max_vma?
      last_vma = last_addr ? last_addr.end_vma + 1 : start_vma
      return [] if (last_vma > max_vma || change == 0)

      # Fill the gap based on the previous changeset
      build_address_range(last_vma, max_vma - last_vma + 1, change - 1, true, 
                          strict_end)
      end

=begin rdoc
Recursively apply patches to image starting at changeset 1 and ending at
specified/current changeset.
=end
    def patched_image(img, change)
      return img if change == 0

      # Apply each changeset to contents of base image
      buf = img.contents
      (change).times do |i|
        cb = changeset_obj(i+1).changed_bytes
        cb.keys.each { |vma| buf[vma_offset(vma)] = cb[vma] }
      end
      # TODO: cache images?

      Image.new(buf, "Changeset #{change} of image #{img.ident}")
    end

  end

end
