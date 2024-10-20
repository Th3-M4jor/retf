# frozen_string_literal: true

require 'benchmark/ips'
require_relative '../lib/retf'

LONG_ARRAY = (1..100).to_a.freeze

LONG_STRING = 'abc' * 100

NESTED_HASH = { a: { b: 2 }.freeze }.freeze

HASH_WITH_ARRAY = { a: [1, 2].freeze }.freeze

HASH_WITH_MANY_ELEMENTS = {
  a: 1,
  b: 2,
  c: 3,
  d: 4,
  e: 5,
  f: 6
}.freeze

LARGE_HASH = {
  foo: LONG_ARRAY,
  bar: LONG_STRING,
  baz: NESTED_HASH,
  qux: HASH_WITH_ARRAY,
  quux: HASH_WITH_MANY_ELEMENTS
}.freeze

RubyVM::YJIT.enable

Benchmark.ips do |x|
  # Configure the number of seconds used during
  # the warmup phase (default 2) and calculation phase (default 5)
  x.config(warmup: 2, time: 5)

  x.report('encode long array') do
    Retf.encode(LONG_ARRAY)
  end

  x.report('encode long string') do
    Retf.encode(LONG_STRING)
  end

  x.report('encode nested hash') do
    Retf.encode(NESTED_HASH)
  end

  x.report('encode hash with array') do
    Retf.encode(HASH_WITH_ARRAY)
  end

  x.report('encode hash with many elements') do
    Retf.encode(HASH_WITH_MANY_ELEMENTS)
  end

  x.report('encode large hash') do
    Retf.encode(LARGE_HASH)
  end

  x.report('encode large hash with compression') do
    Retf.encode(LARGE_HASH, compress: true)
  end
end
