# frozen_string_literal: true

require 'benchmark/ips'
require_relative '../lib/retf'

EMPTY_MAP = [131, 116, 0].pack('CCN').freeze

MAP_WITH_ONE_ELEMENT = [
  131, 116, 0, 0, 0, 1, 97, 42, 109, 0, 0, 0,
  10, 116, 104, 101, 32, 97, 110,
  115, 119, 101, 114
].pack('C*').freeze

MAP_WITH_NESTED_MAPS = [
  131, 116, 0, 0, 0, 3, 97, 42, 107, 0, 1, 1, 119, 1, 97, 116, 0, 0, 0, 1, 108,
  0, 0, 0, 2, 109, 0, 0, 0, 1, 97, 109, 0, 0, 0, 1, 99, 106, 119, 1, 120, 109,
  0, 0, 0, 1, 99, 106
].pack('C*').freeze

COMPRESSED_STRING = [
  131, 80, 0, 0, 1, 49, 120, 156,
  203, 101, 96, 96, 212, 73, 76, 74, 30, 69, 68,
  34, 0, 63, 40, 115, 115
].pack('C*').freeze

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
end
