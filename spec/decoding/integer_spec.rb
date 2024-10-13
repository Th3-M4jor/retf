# frozen_string_literal: true

require 'retf'

RSpec.describe Integer do
  describe 'bytes' do
    it 'decodes an unsigned byte' do
      byte = 255

      encoded = [131, 97, byte].pack('CCC')

      expect(Retf.decode(encoded)).to eq byte
    end

    it 'decodes an unsigned byte with a value of 0' do
      byte = 0

      encoded = [131, 97, byte].pack('CCC')

      expect(Retf.decode(encoded)).to eq byte
    end
  end

  describe 'signed integers' do
    it 'decodes a positive integer' do
      integer = 65_535

      # Can't use 'N' because they are signed 32-bit
      # big-endian integers
      encoded = [131, 98, integer].pack('CCl>')

      expect(Retf.decode(encoded)).to eq integer
    end

    it 'decodes a negative integer' do
      integer = -65_535

      encoded = [131, 98, integer].pack('CCl>')

      expect(Retf.decode(encoded)).to eq integer
    end
  end

  describe 'small big integers' do
    it 'decodes a positive big integer' do
      int = 2**42

      # 110 is the SMALL_BIG_EXT tag
      # 6 is the number of bytes
      # then its the sign
      # followed by the bytes
      encoded = [131, 110, 6, 0, 0, 0, 0, 0, 0, 4].pack('C*')

      expect(Retf.decode(encoded)).to eq int
    end

    it 'decodes a negative big integer' do
      int = -2**42

      encoded = [131, 110, 6, 1, 0, 0, 0, 0, 0, 4].pack('C*')

      expect(Retf.decode(encoded)).to eq int
    end
  end

  describe 'large big integers' do
    it 'decodes a huge positive big integer' do
      int = 2**10_000

      # create an array of 1258 zeros
      packed_digits = Array.new(1258, 0)
      packed_digits[0] = 131 # 131 is the ETF version tag
      packed_digits[1] = 111 # 111 is the LARGE_BIG_EXT tag

      # set the bytes that represent the number of digits
      packed_digits[4] = 4
      packed_digits[5] = 227

      # set the only digit to 1
      packed_digits[1257] = 1

      encoded = packed_digits.pack('C*')

      expect(Retf.decode(encoded)).to eq int
    end

    it 'decodes a huge negative big integer' do
      int = -2**10_000

      packed_digits = Array.new(1258, 0)
      packed_digits[0] = 131
      packed_digits[1] = 111

      packed_digits[4] = 4
      packed_digits[5] = 227

      packed_digits[1257] = 1

      # set the sign bit
      packed_digits[6] = 1

      encoded = packed_digits.pack('C*')

      expect(Retf.decode(encoded)).to eq int
    end
  end
end
