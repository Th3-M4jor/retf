# frozen_string_literal: true

require 'retf'

RSpec.describe Retf::Tuple do
  it 'encodes a tuple' do
    encoded = Retf.encode(described_class.new(1, 2, 3))

    expected = [
      131, 104, 3, 97, 1, 97, 2, 97, 3
    ].pack('C*')

    expect(encoded.bytes).to eq(expected.bytes)
  end

  it 'encodes a tuple as part of a keyword list' do
    list = [
      described_class.new(:break, 1),
      described_class.new(:free, 2)
    ]

    encoded = Retf.encode(list)

    expected = [
      131, 108, 2,
      104, 2, 119, 5, 'break', 97, 1,
      104, 2, 119, 4, 'free', 97, 2,
      106
    ].pack('CCNC4a*C2C4a*C2C')

    expect(encoded).to eq(expected)
  end
end
