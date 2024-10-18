# frozen_string_literal: true

require 'retf'

RSpec.describe Hash do
  it 'encodes an empty hash' do
    encoded = Retf.encode({})

    expected = [
      131, 116, 0
    ].pack('CCN')

    expect(encoded).to eq(expected)
  end

  it 'encodes a hash with one key-value pair' do
    encoded = Retf.encode({ a: 1 })

    expected = [
      131, 116, 1, 119, 1, 'a', 97, 1
    ].pack('CCNCCaCC')

    expect(encoded).to eq(expected)
  end

  it 'encodes a hash with nested hashes' do
    encoded = Retf.encode({ a: { b: 2 } })

    expected = [
      131, 116, 1,
      119, 1, 'a',
      116, 1, 119,
      1, 'b', 97, 2
    ].pack('CCNCCaCNCCaCC')

    expect(encoded).to eq(expected)
  end

  it 'encodes a hash with an array as a value' do
    encoded = Retf.encode({ a: [1, 2] })

    expected = [
      131, 116, 1,
      119, 1, 'a',
      108, 2, 97, 1, 97, 2, 106
    ].pack('CCNCCaCNCCCCC')

    expect(encoded).to eq(expected)
  end
end
