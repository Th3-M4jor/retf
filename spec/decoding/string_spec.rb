# frozen_string_literal: true

require 'retf'
require 'securerandom'

RSpec.describe String do
  # Reminder: 131 is the ETF version tag
  # 109 is the binary tag
  # the next 4 bytes in Network Byte Order
  # are the size of the string
  # the rest of the bytes are the string itself

  it 'decodes a string of random bytes' do
    str = SecureRandom.bytes(10)

    encoded = [131, 109, str.bytesize, str].pack('CCNa*')

    expect(Retf.decode(encoded)).to eq str
  end

  it 'decodes a string with unicode characters' do
    str = 'hello, 世界'

    encoded = [131, 109, str.bytesize, str].pack('CCNa*')

    # Because erlang binaries are arbitrary byte sequences
    # we need to force the encoding to binary to compare
    # it correctly

    decoded = Retf.decode(encoded).force_encoding(Encoding::UTF_8)

    expect(decoded).to eq str
  end

  it 'decodes a string with a size of 0' do
    str = ''

    encoded = [131, 109, str.bytesize, str].pack('CCNa*')

    expect(Retf.decode(encoded)).to eq str
  end

  it 'decodes a string with a size of 255' do
    str = 'a' * 255

    encoded = [131, 109, str.bytesize, str].pack('CCNa*')

    expect(Retf.decode(encoded)).to eq str
  end

  it 'decodes a string with a size of 65536' do
    str = 'a' * 65_536

    encoded = [131, 109, str.bytesize, str].pack('CCNa*')

    expect(Retf.decode(encoded)).to eq str
  end

  it 'decodes a string that is part of a list' do
    str = 'this is a test string'

    encoded = [131, 108, 1, 109, str.bytesize, str, 106].pack('CCNCNa*C')

    expect(Retf.decode(encoded)).to eq [str]
  end

  it 'decodes an Erlang style string' do
    str = 'hello there!'

    # Erlang strings are actually lists of integers
    # 107 is just a special case for these lists
    encoded = [131, 107, str.bytesize, str].pack('CCna*')

    expect(Retf.decode(encoded)).to eq 'hello there!'
  end
end
