# frozen_string_literal: true

require 'benchmark/ips'
require_relative '../lib/retf'
require_relative '../spec/support/test_classes'

EMPTY_MAP = Retf.encode({}).freeze

MAP_WITH_ONE_ELEMENT = Retf.ecnode({ 42 => 'the answer' }).freeze

MAP_WITH_NESTED_MAPS = Retf.encode({ 42 => 'the answer', a: { [1, 2] => 'z' } }).freeze

COMPRESSED_STRING = [
  131, 80, 0, 0, 1, 49, 120, 156,
  203, 101, 96, 96, 212, 73, 76, 74, 30, 69, 68,
  34, 0, 63, 40, 115, 115
].pack('C*').freeze

LONG_ARRAY = Retf.encode(Array.new(1000, 42)).freeze

DECODABLE_CLASS = Retf.encode(Test::MyClass.new(42, 'the answer')).freeze

NON_DECODABLE_CLASS = begin
  a = :a.to_etf
  b = :b.to_etf
  struct = :__struct__.to_etf
  forty_two = 42.to_etf
  the_answer = 'the answer'.to_etf
  klass = Test::MyOtherClass.to_etf

  encoded_value = [131, 116, 3].pack('CCN')
  encoded_value << a << forty_two << b << the_answer << struct << klass
end.freeze

RubyVM::YJIT.enable

Benchmark.ips do |x|
  # Configure the number of seconds used during
  # the warmup phase (default 2) and calculation phase (default 5)
  x.config(warmup: 2, time: 5)

  x.report('decode empty map') do
    Retf.decode(EMPTY_MAP)
  end

  x.report('decode map with one element') do
    Retf.decode(MAP_WITH_ONE_ELEMENT)
  end

  x.report('decode map with nested maps') do
    Retf.decode(MAP_WITH_NESTED_MAPS)
  end

  x.report('decode compressed string') do
    Retf.decode(COMPRESSED_STRING)
  end

  x.report('decode long array') do
    Retf.decode(LONG_ARRAY)
  end

  x.report('decode decodable class') do
    Retf.decode(DECODABLE_CLASS)
  end

  x.report('decode non-decodable class') do
    Retf.decode(NON_DECODABLE_CLASS)
  end
end
