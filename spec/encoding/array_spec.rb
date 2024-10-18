# frozen_string_literal: true

require 'retf'

RSpec.describe Array do
  it 'encodes an empty array' do
    encoded = Retf.encode([])
    expect(encoded.bytes).to eq([131, 106])
  end

  it 'encodes an array with one element' do
    encoded = Retf.encode([1])

    expected = [
      131, 108, 1, 97, 1, 106
    ].pack('CCNCCC')

    expect(encoded).to eq(expected)
  end

  it 'encodes an array with nested arrays' do
    encoded = Retf.encode([1, [2, 3]])

    expected = [
      131, 108, 2, 97, 1, 108, 2, 97, 2, 97, 3, 106, 106
    ].pack('CCNCCCNC*')

    expect(encoded).to eq(expected)
  end
end
