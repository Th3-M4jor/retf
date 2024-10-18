# frozen_string_literal: true

require 'retf'

RSpec.describe Retf::PID do
  it 'encodes a pid' do
    encoded = Retf.encode(described_class.new(111, 2, 3, :'nonode@nohost'))

    node = 'nonode@nohost'

    expected = [
      131, 88, 119, node.bytesize, node,
      111, 2, 3
    ].pack('CCCCa*NNN')

    expect(encoded).to eq(expected)
  end

  it 'encodes a pid as part of an array' do
    encoded = Retf.encode([described_class.new(111, 2, 3, :'nonode@nohost')])

    node = 'nonode@nohost'

    expected = [
      131, 108, 1, 88, 119, node.bytesize, node, 111, 2, 3, 106
    ].pack('CCNCCCa*NNNC')

    expect(encoded).to eq(expected)
  end
end
