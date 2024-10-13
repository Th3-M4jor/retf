# frozen_string_literal: true

require 'retf'
require 'securerandom'

RSpec.describe Retf::Reference do
  it 'decodes a reference' do
    node = :'nonode@nohost'.to_etf
    creation = SecureRandom.random_number(1..Retf::USIZE_MAX)

    # make 4 random 32-bit Big Endian integers
    random_id = SecureRandom.random_bytes(16).unpack('N4')

    encoded = [131, 90, 4, node, creation, *random_id].pack('CCna*NN*')

    expected_reference = described_class.new(creation, random_id, :'nonode@nohost')

    expect(Retf.decode(encoded)).to eq(expected_reference)
  end
end
