# frozen_string_literal: true

require 'retf'

RSpec.describe Array do
  it 'decodes an empty array' do
    encoded = [131, 106].pack('CC')

    expect(Retf.decode(encoded)).to eq []
  end

  it 'decodes an array with one element' do
    # in ETF, the tail of the list is always NIL_EXT when
    # its a "proper list"
    encoded = [131, 108, 1, 97, 42, 106].pack('CCNCCC')

    expect(Retf.decode(encoded)).to eq [42]
  end

  it 'decodes an array with multiple elements' do
    encoded = [131, 108, 3, 97, 42, 97, 43, 97, 44, 106].pack('CCNC*')

    expect(Retf.decode(encoded)).to eq [42, 43, 44]
  end

  it 'decodes an array that was an improper list' do
    # improper list because the tail is not NIL_EXT
    # Note that the tail is actually an integer
    # and not counted in the size of the list
    encoded = [131, 108, 2, 97, 42, 97, 43, 97, 44].pack('CCNC*')

    expect(Retf.decode(encoded)).to eq [42, 43, 44]
  end

  it 'decodes an array with nested arrays' do
    encoded = [131, 108, 0, 0, 0, 2, 108, 0, 0, 0, 2, 109, 0, 0, 0, 1, 97, 109, 0, 0, 0, 1,
               98, 106, 108, 0, 0, 0, 1, 109, 0, 0, 0, 1, 99, 106, 106].pack('C*')

    expect(Retf.decode(encoded)).to eq [%w[a b], %w[c]]
  end
end
