# frozen_string_literal: true

require 'retf'

RSpec.describe Retf::Tuple do
  describe 'small tuples' do
    it 'decodes an empty tuple' do
      encoded = [131, 104, 0].pack('CCC')

      expect(Retf.decode(encoded)).to eq(described_class.new)
    end

    it 'decodes a tuple with 1 element' do
      str = 'a'.to_etf

      encoded = [131, 104, 1, str].pack('CCCa*')

      expect(Retf.decode(encoded)).to eq(described_class.new('a'))
    end

    it 'decodes a tuple with 2 elements' do
      ok_sym = :ok.to_etf
      arr = [1, 2, 3].to_etf

      encoded = [131, 104, 2, ok_sym, arr].pack('CCCa*a*')

      expect(Retf.decode(encoded)).to eq(described_class.new(:ok, [1, 2, 3]))
    end

    it 'decodes a tuple with 255 elements' do
      expected_elements = Array.new(255) { |i| i }

      elements = expected_elements.map(&:to_etf).join

      encoded = [131, 104, 255, *elements].pack('CCCa*')

      expect(Retf.decode(encoded)).to eq(described_class.new(*expected_elements))
    end

    it 'decodes a tuple as part of a nested structure' do
      str = 'a'.to_etf

      encoded_tuple = [104, 1, str].pack('CCa*')

      encoded = [131, 104, 1, encoded_tuple].pack('CCCa*')

      expect(Retf.decode(encoded)).to eq(described_class.new(described_class.new('a')))
    end
  end

  describe 'large tuples' do
    it 'decodes a tuple with 256 elements' do
      expected_elements = Array.new(256) { _1 }

      elements = expected_elements.map(&:to_etf).join

      encoded = [131, 105, 256, elements].pack('CCNa*')

      expect(Retf.decode(encoded)).to eq(described_class.new(*expected_elements))
    end

    it 'decodes a large tuple as part of a nested structure' do
      inner_elements = Array.new(256) { _1 }

      encoded_elements = inner_elements.map(&:to_etf).join

      encoded_tuple = [105, 256, encoded_elements].pack('CNa*')

      atom = :a.to_etf

      encoded = [131, 116, 1, atom, encoded_tuple].pack('CCNa*a*')

      expect(Retf.decode(encoded)).to eq(a: described_class.new(*inner_elements))
    end

    it 'decodes a tuple with 2**16 elements' do
      expected_elements = Array.new(2**16) { _1 }

      elements = expected_elements.map(&:to_etf).join

      encoded = [131, 105, 2**16, *elements].pack('CCNa*')

      expect(Retf.decode(encoded)).to eq(described_class.from_array(expected_elements))
    end
  end
end
