# frozen_string_literal: true

require 'retf'

RSpec.describe Retf::Reference do
  it 'encodes a reference' do
    creation = SecureRandom.random_number(1..Retf::USIZE_MAX)

    # make 4 random 32-bit Big Endian integers
    random_id = SecureRandom.random_bytes(16).unpack('N4')

    ref = described_class.new(creation, random_id, :'nonode@nohost')
    encoded = Retf.encode(ref)

    node = 'nonode@nohost'

    expected = [
      131, 90, 4,
      119, node.bytesize, node,
      creation, *random_id
    ].pack('CCnCCa*NN4')

    expect(encoded).to eq(expected)
  end

  it 'encodes a reference as part of an array' do
    creation = SecureRandom.random_number(1..Retf::USIZE_MAX)

    # make 4 random 32-bit Big Endian integers
    random_id = SecureRandom.random_bytes(16).unpack('N4')

    ref = described_class.new(creation, random_id, :'nonode@nohost')
    encoded = Retf.encode([ref])

    node = 'nonode@nohost'

    expected = [
      131, 108, 1,
      90, 4,
      119, node.bytesize, node,
      creation, *random_id, 106
    ].pack('CCNCnCCa*NN4C')

    expect(encoded).to eq(expected)
  end
end
