# frozen_string_literal: true

require 'retf'

RSpec.describe Hash do
  it 'decodes an empty map' do
    encoded = [131, 116, 0].pack('CCN')

    expect(Retf.decode(encoded)).to eq({})
  end

  it 'decodes a map with one element' do
    encoded = [131, 116, 0, 0, 0, 1, 97, 42, 109, 0, 0, 0, 10, 116, 104, 101, 32, 97, 110,
               115, 119, 101, 114].pack('C*')

    expect(Retf.decode(encoded)).to eq({ 42 => 'the answer' })
  end

  it 'decodes a map with multiple elements' do
    encoded = [131, 116, 0, 0, 0, 2, 119, 1, 99, 119, 1, 100, 119, 1, 97, 119, 1, 98].pack('C*')

    expect(Retf.decode(encoded)).to eq({ a: :b, c: :d })
  end

  it 'decodes a map with mixed key types' do
    encoded = [131, 116, 0, 0, 0, 3, 97, 42, 107, 0, 1, 1, 119, 1, 97, 119, 1, 98, 109, 0, 0,
               0, 1, 99, 106].pack('C*')

    expect(Retf.decode(encoded)).to eq({ 42 => [1], a: :b, 'c' => [] })
  end

  it 'decodes a map with nested maps' do
    encoded = [131, 116, 0, 0, 0, 3, 97, 42, 107, 0, 1, 1, 119, 1, 97, 116, 0, 0, 0, 1, 108,
               0, 0, 0, 2, 109, 0, 0, 0, 1, 97, 109, 0, 0, 0, 1, 99, 106, 119, 1, 120, 109,
               0, 0, 0, 1, 99, 106].pack('C*')

    expect(Retf.decode(encoded)).to eq({ a: { %w[a c] => :x }, 42 => [1], 'c' => [] })
  end
end
