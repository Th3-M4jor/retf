# frozen_string_literal: true

require 'retf'

RSpec.describe Symbol do
  it 'encodes nil as an atom' do
    encoded = Retf.encode(nil)

    expect(encoded.bytes).to eq([131, 119, 3, 110, 105, 108])
  end

  it 'encodes false as an atom' do
    encoded = Retf.encode(false)

    expect(encoded.bytes).to eq([131, 119, 5, 102, 97, 108, 115, 101])
  end

  it 'encodes true as an atom' do
    encoded = Retf.encode(true)

    expect(encoded.bytes).to eq([131, 119, 4, 116, 114, 117, 101])
  end

  it 'encodes a non-quoted symbol' do
    encoded = Retf.encode(:hello)

    expect(encoded.bytes).to eq([131, 119, 5, 104, 101, 108, 108, 111])
  end

  it 'encodes a symbol that has utf-8 characters' do
    encoded = Retf.encode(:'hello, 世界')

    expect(encoded.bytes).to eq([131, 119, 13, 104, 101, 108, 108, 111, 44, 32, 228, 184, 150, 231,
                                 149, 140])
  end

  it 'encodes class names as atoms' do
    encoded = Retf.encode(String)

    class_name = 'Elixir.String'

    expect(encoded.bytes).to eq([131, 119, class_name.bytesize, *class_name.bytes])
  end
end
