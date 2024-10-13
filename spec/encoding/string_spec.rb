# frozen_string_literal: true

require 'retf'
require 'securerandom'

RSpec.describe String do
  it 'encodes a string' do
    str = 'hello'

    encoded = Retf.encode(str)

    expect(encoded.bytes).to eq([131, 109, 0, 0, 0, 5, 104, 101, 108, 108, 111])
  end

  it 'encodes an empty string' do
    str = ''

    encoded = Retf.encode(str)

    expect(encoded.bytes).to eq([131, 109, 0, 0, 0, 0])
  end

  it 'encodes a string with a length of 255' do
    str = 'a' * 255

    encoded = Retf.encode(str)

    expect(encoded.bytes).to eq([131, 109, 0, 0, 0, 255, *str.bytes])
  end

  it 'encodes a string with unicode characters' do
    str = 'hello, 世界'

    encoded = Retf.encode(str)

    expect(encoded.bytes).to eq([131, 109, 0, 0, 0, 13, *str.bytes])
  end

  it 'encodes a string of random bytes' do
    str = SecureRandom.bytes(10)

    encoded = Retf.encode(str)

    expect(encoded.bytes).to eq([131, 109, 0, 0, 0, 10, *str.bytes])
  end
end
