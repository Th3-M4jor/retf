# frozen_string_literal: true

require 'retf'

RSpec.describe 'zlib deflated etf' do
  it 'encodes a single float and compresses it' do
    compressed_etf = Retf.encode(3.14, compress: true)

    expected = [131, 80, 0, 0, 0, 9, 120, 156, 115, 115,
                224, 148, 219, 17, 248, 186, 85, 30, 0,
                14, 56, 3, 70].pack('C*')

    expect(compressed_etf).to eq(expected)
  end

  it 'encodes a large string and compresses it' do
    compressed_etf = Retf.encode('abc' * 100, compress: true)

    expected = [
      131, 80, 0, 0, 1, 49, 120,
      156, 203, 101, 96, 96, 212,
      73, 76, 74, 30, 69, 68, 34,
      0, 63, 40, 115, 115
    ].pack('C*')

    expect(compressed_etf).to eq(expected)
  end

  it 'encodes a more complex term and compresses it' do
    term = {
      a: 42,
      b: 'hello',
      c: [1, 2, 3]
    }

    compressed_etf = Retf.encode(term, compress: true)

    expected = [131, 80, 0, 0, 0, 38, 120, 156, 43, 97, 96, 96, 96,
                46, 103, 76, 76, 212, 42, 103, 76, 202, 5, 114, 88, 51, 82, 115,
                114, 242, 203, 25, 147, 115, 64, 50, 137, 140, 137, 76, 137,
                204, 89, 0, 155, 241, 8, 25].pack('C*')

    expect(compressed_etf).to eq(expected)
  end
end
