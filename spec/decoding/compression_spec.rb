# frozen_string_literal: true

require 'retf'
require 'zlib'

RSpec.describe 'zlib deflated etf' do
  it 'decodes compressed etf generated by erlang' do
    bytes = [
      131, 80, 0, 0, 1, 49, 120, 156,
      203, 101, 96, 96, 212, 73, 76, 74, 30, 69, 68,
      34, 0, 63, 40, 115, 115
    ].pack('C*')

    expect(Retf.decode(bytes)).to eq('abc' * 100)
  end

  it 'decodes a compressed etf generated by hand' do
    float = 42.0

    encoded = [
      70, float
    ].pack('CG')

    uncompressed_size = encoded.bytesize

    compressed = Zlib::Deflate.deflate(encoded)

    compressed_etf = [131, 80, uncompressed_size, compressed].pack('CCNa*')

    expect(Retf.decode(compressed_etf)).to eq(float)
  end
end