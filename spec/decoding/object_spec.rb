# frozen_string_literal: true

require 'retf'

require_relative '../support/test_classes'

RSpec.describe Object do
  it 'does nothing when the class does not support etf decoding' do
    a = :a.to_etf
    b = :b.to_etf
    struct = :__struct__.to_etf
    forty_two = 42.to_etf
    the_answer = 'the answer'.to_etf
    klass = Test::MyOtherClass.to_etf

    # we're cheating a bit here and abusing the fact that
    # Ruby Hashes preserve insertion order
    # this is not the case for Erlang maps
    # which are unordered
    encoded_value = [131, 116, 3].pack('CCN')
    encoded_value << a << forty_two << b << the_answer << struct << klass

    expect(Retf.decode(encoded_value)).to eq(a: 42, b: 'the answer', __struct__: Test::MyOtherClass)
  end

  it 'decodes a class instance' do
    a = :a.to_etf
    b = :b.to_etf
    struct = :__struct__.to_etf
    forty_two = 42.to_etf
    the_answer = 'the answer'.to_etf
    klass = Test::MyClass.to_etf

    # we're cheating a bit here and abusing the fact that
    # Ruby Hashes preserve insertion order
    # this is not the case for Erlang maps
    # which are unordered
    encoded_value = [131, 116, 3].pack('CCN')
    encoded_value << a << forty_two << b << the_answer << struct << klass

    obj = Test::MyClass.new(42, 'the answer')
    expect(Retf.decode(encoded_value)).to eq(obj)
  end

  it 'supports decoding nested classes' do
    a = :a.to_etf
    b = :b.to_etf
    struct = :__struct__.to_etf
    forty_two = 42.to_etf
    the_answer = 'the answer'.to_etf
    klass = Test::MyClass.to_etf

    encoded_class = [116, 3].pack('CN')
    encoded_class << a << forty_two << b << the_answer << struct << klass
    # we're cheating a bit here and abusing the fact that
    # Ruby Hashes preserve insertion order
    # this is not the case for Erlang maps
    # which are unordered
    encoded_value = [131, 116, 3].pack('CCN')
    encoded_value << a << encoded_class << b << the_answer << struct << klass

    obj = Test::MyClass.new(42, 'the answer')
    expected_obj = Test::MyClass.new(obj, 'the answer')

    expect(Retf.decode(encoded_value)).to eq(expected_obj)
  end
end
