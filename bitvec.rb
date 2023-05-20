#!/usr/bin/env ruby

require 'test/unit'

class BitVector
  BITS_PER_WORD = 32
  WORD_PACK = 'L' # CSLQ
  attr_reader :size

  def initialize(num_bits, data=nil)
    @size = num_bits
    @words = Array.new(((num_bits.to_i / BITS_PER_WORD)+1), 0)
    @spare_bits = @size % BITS_PER_WORD
    if (data.is_a? Fixnum and data > 1)
      # TODO: set bits that are set in data
    else
      set(data)
    end
  end

  def num_words
    @words.count
  end

  def words
    last_word = @words.last
    len = @spare_bits
    low_bit = BITS_PER_WORD - @spare_bits
    last_word = (last_word >> low_bit) & ~(-1 << @spare_bits)
    (@words[0, @words.length - 1] << last_word).to_enum
  end

  def set(idx)
    return if not idx
    [idx].flatten.each do |i|
      with_bit(i) { |val, (w_idx, b_idx)| 
         w = @words[w_idx]
         @words[w_idx] = w | (1 << (BITS_PER_WORD - b_idx - 1))
      }
    end
  end

  def clear(idx)
    return if not idx
    [idx].flatten.each do |i|
      with_bit(i) { |val, (w_idx, b_idx)| 
         w = @words[w_idx]
         @words[w_idx] = w & ~(1 << (BITS_PER_WORD - b_idx - 1))
      }
    end
  end

  def set?(idx)
    return if not idx
    [idx].flatten.inject(false) do |rv, i|
      rv |= with_bit(i) { |val, (w_idx, b_idx)| val == 1 }
    end
  end

  def equal?(other)
    return false if (other.size != @size)
    a = self.words.to_a
    xor = 0
    other.words.each_with_index { |b, idx| xor |= (a[idx] ^ b) }
    (xor == 0)
  end

  def extract(offset, len)
    bv = BitVector.new(len)

    w_idx = offset / BITS_PER_WORD
    b_idx = offset % BITS_PER_WORD

    # not too many ways to make this much faster
    w = @words[w_idx]
    len.times do |out_idx|
      bv.set(out_idx) if (w & (1 << (BITS_PER_WORD - b_idx - 1)) > 0)
      b_idx += 1
      if b_idx == BITS_PER_WORD
        b_idx = 0
        w_idx += 1
        w = @words[w_idx]
      end
    end

    bv
  end

  def include?(other)
    delta = @size - other.size
    return false if (delta < 0)
    return equal?(other) if (delta == 0)
    delta.times do |offset|
      bv = extract(offset, other.size)
      return true if (other.equal? bv)
    end
    false
  end

  def to_s
    str = words.to_a.pack(WORD_PACK).unpack("b*").first[0,@size].reverse
  end

  private 
  def with_bit(idx, &block)
    word_idx = idx / BITS_PER_WORD
    bit_idx = idx % BITS_PER_WORD
    yield ((@words[word_idx] >> (BITS_PER_WORD - bit_idx - 1)) & 0x1),
          [word_idx, bit_idx]
  end
end

class BitVecTest < Test::Unit::TestCase
  def test_bv_create
    size = rand(200)
    bv = BitVector.new(size)
    assert_equal(size, bv.size)
    assert(bv.num_words * BitVector::BITS_PER_WORD >= size)
  end

  def test_1_single_word
    bv = BitVector.new(10)
    assert_equal(10, bv.size)
    assert_equal(1, bv.num_words)
    assert_equal(1, bv.words.to_a.length)
    assert_equal(0, bv.words.first)
    bv.set(9)  # maximum (rightmost) bit : 9
    assert_equal(1, bv.words.first)
    bv.clear(9)
    assert_equal(0, bv.words.first)
    bv.set(0)  # minimum (leftmost) bit : 0
    assert_equal(1 << 9, bv.words.first)
  end

  def test_2_two_words
    bv = BitVector.new(50)
    assert_equal(50, bv.size)
    assert_equal(2, bv.num_words)
    assert_equal(2, bv.words.to_a.length)
    assert_equal(0, bv.words.first)
    bv.set(10) # bit (31 - 10) of word 1
    assert_equal(1 << 21, bv.words.first)
    bv.clear(10) 
    assert_equal(0, bv.words.first)
    bv.set(0) # bit (31 - 1) of word 1
    assert_equal(1 << 31, bv.words.first)
    bv.set(32) # bit (18 - 1) of word 2
    assert_equal(1 << 17, bv.words.to_a[-1])
    bv.clear(32) 
    assert_equal(0 << 17, bv.words.to_a[-1])
    bv.set(49) # bit (1) of word 2
    assert_equal(1, bv.words.to_a[-1])

  end

  def test_3_equals
    a = BitVector.new(100)
    b = BitVector.new(99)
    assert(! (a.equal? b))

    b = BitVector.new(100)
    assert(a.equal? b)

    # setting A should not match
    a.set(75)
    assert(! (a.equal? b))
    b.set(75)
    assert(a.equal? b)

    # setting B should not match
    b.set(37)
    assert(! (a.equal? b))
    a.set(37)
    assert(a.equal? b)

    # setting A again should not match
    a.set(0)
    assert(! (a.equal? b))
    b.set(0)
    assert(a.equal? b)
  end

  def test_4_contains
    # |a| < |b|
    a = BitVector.new(100)
    b = BitVector.new(101)
    assert(! (a.include? b))

    # |a| == |b|
    b = BitVector.new(100)
    assert(a.include? b)

    b.set(1)
    assert(! (a.include? b))

    # 1011 in 0011011001
    a = BitVector.new(10)
    a.set([2,3,5,6,9])
    b = BitVector.new(4)
    b.set([0,2,3])
    assert(a.include? b)
    # 1010 not in 0011011001
    b.clear(3)
    assert(! (a.include? b))

    # 11001110011100111001110011100111001 in
    # 10101101100111001110011100111001110011100111101010
    a = BitVector.new(50)
    a.set([0,2,4,5,7,8,11,12,13,16,17,18,21,22,23,26,27,28,31,32,33,36,37,38,
           41,42,43,44,46,48])
    b = BitVector.new(35)
    b.set([0,1,4,5,6,9,10,11,14,15,16,19,20,21,24,25,26,29,30,31,34])
    assert(a.include? b)
    b.set(7)
    assert(! (a.include? b))
  end
end
