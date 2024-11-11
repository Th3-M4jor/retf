# frozen_string_literal: true

require 'benchmark/ips'
require_relative '../lib/retf'
require 'msgpack'
require 'json'

LARGE_INTEGER_PAIR = [(2**32) - 1, (2**63) - 1].freeze

JSON_LARGE_INTEGER_PAIR = LARGE_INTEGER_PAIR.to_json.freeze
MSG_PACK_LARGE_INTEGER_PAIR = MessagePack.pack(LARGE_INTEGER_PAIR).freeze
ETF_LARGE_INTEGER_PAIR = Retf.encode(LARGE_INTEGER_PAIR).freeze

LONG_ARRAY = ([123, 'abc', { a: :b, c: [(2**63) - 1], d: 'asdfed' * 10 }] * 10).freeze

JSON_LONG_ARRAY = LONG_ARRAY.to_json.freeze
MSG_PACK_LONG_ARRAY = MessagePack.pack(LONG_ARRAY).freeze
ETF_LONG_ARRAY = Retf.encode(LONG_ARRAY).freeze

LONG_STRING = 'abc' * 100

JSON_LONG_STRING = LONG_STRING.to_json.freeze
MSG_PACK_LONG_STRING = MessagePack.pack(LONG_STRING).freeze
ETF_LONG_STRING = Retf.encode(LONG_STRING).freeze

LONG_INT_ARRY = (150..350).to_a.freeze

JSON_LONG_INT_ARRY = LONG_INT_ARRY.to_json.freeze
MSG_PACK_LONG_INT_ARRY = MessagePack.pack(LONG_INT_ARRY).freeze
ETF_LONG_INT_ARRY = Retf.encode(LONG_INT_ARRY).freeze

NESTED_HASH = { a: { b: 2 }.freeze }.freeze

JSON_NESTED_HASH = NESTED_HASH.to_json.freeze
MSG_PACK_NESTED_HASH = MessagePack.pack(NESTED_HASH).freeze
ETF_NESTED_HASH = Retf.encode(NESTED_HASH).freeze

HASH_WITH_ARRAY = { a: [1, 2].freeze }.freeze

JSON_HASH_WITH_ARRAY = HASH_WITH_ARRAY.to_json.freeze
MSG_PACK_HASH_WITH_ARRAY = MessagePack.pack(HASH_WITH_ARRAY).freeze
ETF_HASH_WITH_ARRAY = Retf.encode(HASH_WITH_ARRAY).freeze

HASH_WITH_MANY_ELEMENTS = {
  a: 1,
  b: 2,
  c: 3,
  d: 4,
  e: 5,
  f: 6
}.freeze

JSON_HASH_WITH_MANY_ELEMENTS = HASH_WITH_MANY_ELEMENTS.to_json.freeze
MSG_PACK_HASH_WITH_MANY_ELEMENTS = MessagePack.pack(HASH_WITH_MANY_ELEMENTS).freeze
ETF_HASH_WITH_MANY_ELEMENTS = Retf.encode(HASH_WITH_MANY_ELEMENTS).freeze

LARGE_HASH = {
  foo: LONG_ARRAY,
  bar: LONG_STRING,
  baz: NESTED_HASH,
  qux: HASH_WITH_ARRAY,
  quux: HASH_WITH_MANY_ELEMENTS
}.freeze

JSON_LARGE_HASH = LARGE_HASH.to_json.freeze
MSG_PACK_LARGE_HASH = MessagePack.pack(LARGE_HASH).freeze
ETF_LARGE_HASH = Retf.encode(LARGE_HASH).freeze

RubyVM::YJIT.enable

Benchmark.ips do |x| # rubocop:disable Metrics/BlockLength
  # Configure the number of seconds used during
  # the warmup phase (default 2) and calculation phase (default 5)
  x.config(warmup: 2, time: 5)

  x.report("JSON - decode large integer pair - #{JSON_LARGE_INTEGER_PAIR.bytesize} bytes") do
    JSON.parse(JSON_LARGE_INTEGER_PAIR)
  end

  x.report("MSGPACK - decode large integer pair - #{MSG_PACK_LARGE_INTEGER_PAIR.bytesize} bytes") do
    MessagePack.unpack(MSG_PACK_LARGE_INTEGER_PAIR)
  end

  x.report("ETF - decode large integer pair - #{ETF_LARGE_INTEGER_PAIR.bytesize} bytes") do
    Retf.decode(ETF_LARGE_INTEGER_PAIR)
  end

  x.report("JSON - decode long integer array - #{JSON_LONG_INT_ARRY.bytesize} bytes") do
    JSON.parse(JSON_LONG_INT_ARRY)
  end

  x.report("MSGPACK - decode long integer array - #{MSG_PACK_LONG_INT_ARRY.bytesize} bytes") do
    MessagePack.unpack(MSG_PACK_LONG_INT_ARRY)
  end

  x.report("ETF - decode long integer array - #{ETF_LONG_INT_ARRY.bytesize} bytes") do
    Retf.decode(ETF_LONG_INT_ARRY)
  end

  x.report("JSON - decode long string - #{JSON_LONG_STRING.bytesize} bytes") do
    JSON.parse(JSON_LONG_STRING)
  end

  x.report("MSGPACK - decode long string - #{MSG_PACK_LONG_STRING.bytesize} bytes") do
    MessagePack.unpack(MSG_PACK_LONG_STRING)
  end

  x.report("ETF - decode long string - #{ETF_LONG_STRING.bytesize} bytes") do
    Retf.decode(ETF_LONG_STRING)
  end

  x.report("JSON - decode long array - #{JSON_LONG_ARRAY.bytesize} bytes") do
    JSON.parse(JSON_LONG_ARRAY)
  end

  x.report("MSGPACK - decode long array - #{MSG_PACK_LONG_ARRAY.bytesize} bytes") do
    MessagePack.unpack(MSG_PACK_LONG_ARRAY)
  end

  x.report("ETF - decode long array - #{ETF_LONG_ARRAY.bytesize} bytes") do
    Retf.decode(ETF_LONG_ARRAY)
  end

  x.report("JSON - decode nested hash - #{JSON_NESTED_HASH.bytesize} bytes") do
    JSON.parse(JSON_NESTED_HASH)
  end

  x.report("MSGPACK - decode nested hash - #{MSG_PACK_NESTED_HASH.bytesize} bytes") do
    MessagePack.unpack(MSG_PACK_NESTED_HASH)
  end

  x.report("ETF - decode nested hash - #{ETF_NESTED_HASH.bytesize} bytes") do
    Retf.decode(ETF_NESTED_HASH)
  end

  x.report("JSON - decode hash with array - #{JSON_HASH_WITH_ARRAY.bytesize} bytes") do
    JSON.parse(JSON_HASH_WITH_ARRAY)
  end

  x.report("MSGPACK - decode hash with array - #{MSG_PACK_HASH_WITH_ARRAY.bytesize} bytes") do
    MessagePack.unpack(MSG_PACK_HASH_WITH_ARRAY)
  end

  x.report("ETF - decode hash with array - #{ETF_HASH_WITH_ARRAY.bytesize} bytes") do
    Retf.decode(ETF_HASH_WITH_ARRAY)
  end

  x.report("JSON - decode hash with many elements - #{JSON_HASH_WITH_MANY_ELEMENTS.bytesize} bytes") do
    JSON.parse(JSON_HASH_WITH_MANY_ELEMENTS)
  end

  x.report("MSGPACK - decode hash with many elements - #{MSG_PACK_HASH_WITH_MANY_ELEMENTS.bytesize} bytes") do
    MessagePack.unpack(MSG_PACK_HASH_WITH_MANY_ELEMENTS)
  end

  x.report("ETF - decode hash with many elements - #{ETF_HASH_WITH_MANY_ELEMENTS.bytesize} bytes") do
    Retf.decode(ETF_HASH_WITH_MANY_ELEMENTS)
  end

  x.report("JSON - decode large hash - #{JSON_LARGE_HASH.bytesize} bytes") do
    JSON.parse(JSON_LARGE_HASH)
  end

  x.report("MSGPACK - decode large hash - #{MSG_PACK_LARGE_HASH.bytesize} bytes") do
    MessagePack.unpack(MSG_PACK_LARGE_HASH)
  end

  x.report("ETF - decode large hash - #{ETF_LARGE_HASH.bytesize} bytes") do
    Retf.decode(ETF_LARGE_HASH)
  end
end
