# frozen_string_literal: true

require 'benchmark/ips'
require_relative '../lib/retf'
require 'msgpack'
require 'json'

LARGE_INTEGER_PAIR = [(2**32) - 1, (2**63) - 1].freeze

LONG_ARRAY = ([123, 'abc', { a: :b, c: [(2**63) - 1], d: 'asdfed' * 10 }] * 10).freeze

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

Benchmark.ips do |x| # rubocop:disable Metrics/BlockLength
  # Configure the number of seconds used during
  # the warmup phase (default 2) and calculation phase (default 5)
  x.config(warmup: 2, time: 5)

  x.report('ETF - encode large integer pair') do
    Retf.encode(LARGE_INTEGER_PAIR)
  end

  x.report('MSGPACK - encode large integer pair') do
    MessagePack.pack(LARGE_INTEGER_PAIR)
  end

  x.report('JSON - encode large integer pair') do
    JSON.dump(LARGE_INTEGER_PAIR)
  end

  x.report('ETF - encode long array') do
    Retf.encode(LONG_ARRAY)
  end

  x.report('MSGPACK - encode long array') do
    MessagePack.pack(LONG_ARRAY)
  end

  x.report('JSON - encode long array') do
    JSON.dump(LONG_ARRAY)
  end

  x.report('ETF - encode long string') do
    Retf.encode(LONG_STRING)
  end

  x.report('MSGPACK - encode long string') do
    MessagePack.pack(LONG_STRING)
  end

  x.report('JSON - encode long string') do
    JSON.dump(LONG_STRING)
  end

  x.report('ETF - encode nested hash') do
    Retf.encode(NESTED_HASH)
  end

  x.report('MSGPACK - encode nested hash') do
    MessagePack.pack(NESTED_HASH)
  end

  x.report('JSON - encode nested hash') do
    JSON.dump(NESTED_HASH)
  end

  x.report('ETF - encode hash with array') do
    Retf.encode(HASH_WITH_ARRAY)
  end

  x.report('MSGPACK - encode hash with array') do
    MessagePack.pack(HASH_WITH_ARRAY)
  end

  x.report('JSON - encode hash with array') do
    JSON.dump(HASH_WITH_ARRAY)
  end

  x.report('ETF - encode hash with many elements') do
    Retf.encode(HASH_WITH_MANY_ELEMENTS)
  end

  x.report('MSGPACK - encode hash with many elements') do
    MessagePack.pack(HASH_WITH_MANY_ELEMENTS)
  end

  x.report('JSON - encode hash with many elements') do
    JSON.dump(HASH_WITH_MANY_ELEMENTS)
  end

  x.report('ETF - encode large hash') do
    Retf.encode(LARGE_HASH)
  end

  x.report('MSGPACK - encode large hash') do
    MessagePack.pack(LARGE_HASH)
  end

  x.report('JSON - encode large hash') do
    JSON.dump(LARGE_HASH)
  end

  x.report('ETF - encode large hash with compression') do
    Retf.encode(LARGE_HASH, compress: true)
  end
end
