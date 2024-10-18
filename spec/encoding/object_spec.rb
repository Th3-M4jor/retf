# frozen_string_literal: true

require 'retf'

require_relative '../support/test_classes'

RSpec.describe Object do
  it 'raises an error when the class does not support etf encoding' do
    klass = Test::MyOtherClass.new(42, 'the answer')

    expect { Retf.encode(klass) }.to raise_error(ArgumentError)
  end

  it 'encodes an object that supports etf encoding' do
    str = 'the answer'

    klass = Test::MyClass.new(42, str)

    encoded = Retf.encode(klass)

    expected = [
      131, 116, 3,
      119, 1, 'a', 97, 42,
      119, 1, 'b', 109, str.bytesize, str,
      119, 10, '__struct__', 119, 19, 'Elixir.Test.MyClass'
    ].pack('CCNCCaCCCCaCNa*CCa*CCa*')

    expect(encoded).to eq(expected)
  end
end
