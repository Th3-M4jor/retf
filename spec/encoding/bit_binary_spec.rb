# frozen_string_literal: true

require 'retf'

RSpec.describe Retf::BitBinary do
  it 'encodes a single byte bit binary' do
    encoded = Retf.encode(described_class.new("\xF0", 4))

    expected = [
      131, 77, 1, 4, 0xF0
    ].pack('CCNCC')

    expect(encoded).to eq(expected)
  end

  it 'encodes a multi byte bit binary' do
    encoded = Retf.encode(described_class.new("\x42\xE0", 4))

    expected = [
      131, 77, 2, 4, 0x42, 0xE0
    ].pack('CCNCCC')

    expect(encoded).to eq(expected)
  end

  it 'encodes a bit binary as part of an array' do
    encoded = Retf.encode([described_class.new("\xF0", 4)])

    expected = [
      131, 108, 1, 77, 1, 4, 0xF0, 106
    ].pack('CCNCNCCC')

    expect(encoded).to eq(expected)
  end
end
