# frozen_string_literal: true

require 'retf'

RSpec.describe Integer do
  describe 'bytes' do
    it 'encodes a small positive integer' do
      encoded = Retf.encode(1)

      expect(encoded.bytes).to eq([131, 97, 1])
    end

    it 'encodes the largest possible small integer' do
      encoded = Retf.encode(255)

      expect(encoded.bytes).to eq([131, 97, 255])
    end
  end

  describe 'signed integers' do
    it 'encodes -1 as a small integer' do
      encoded = Retf.encode(-1)

      expect(encoded.bytes).to eq([131, 98, 255, 255, 255, 255])
    end

    it 'encodes a positive integer' do
      encoded = Retf.encode(65_535)

      expect(encoded.bytes).to eq([131, 98, 0, 0, 255, 255])
    end

    it 'encodes a negative integer' do
      encoded = Retf.encode(-65_535)

      expect(encoded.bytes).to eq([131, 98, 255, 255, 0, 1])
    end

    it 'encodes the largest possible signed 32-bit integer' do
      encoded = Retf.encode((2**31) - 1)

      expect(encoded.bytes).to eq([131, 98, 127, 255, 255, 255])
    end

    it 'encodes the smallest possible signed 32-bit integer' do
      encoded = Retf.encode(-2**31)

      expect(encoded.bytes).to eq([131, 98, 128, 0, 0, 0])
    end
  end

  describe 'small big integers' do
    it 'encodes a positive big integer' do
      encoded = Retf.encode(2**42)

      expect(encoded.bytes).to eq([131, 110, 6, 0, 0, 0, 0, 0, 0, 4])
    end

    it 'encodes a negative big integer' do
      encoded = Retf.encode(-2**42)

      expect(encoded.bytes).to eq([131, 110, 6, 1, 0, 0, 0, 0, 0, 4])
    end
  end

  describe 'large big integers' do
    it 'encodes a positive big integer' do
      encoded = Retf.encode(2**9001)

      expected_array = Array.new(1133) { 0 }

      expected_array[0] = 131
      expected_array[1] = 111
      expected_array[4] = 4
      expected_array[5] = 102
      expected_array[1132] = 2

      expect(encoded.bytes).to eq(expected_array)
    end

    it 'encodes a negative big integer' do
      encoded = Retf.encode(-2**9001)

      expected_array = Array.new(1133) { 0 }

      expected_array[0] = 131
      expected_array[1] = 111
      expected_array[4] = 4
      expected_array[5] = 102
      expected_array[6] = 1
      expected_array[1132] = 2

      expect(encoded.bytes).to eq(expected_array)
    end
  end
end
