# frozen_string_literal: true

require 'zlib'
require 'stringio'

module Retf
  class Decoder # :nodoc:
    def initialize(data)
      @data = StringIO.new(data).binmode
    end

    def decode(skip_version_check: false)
      raise ArgumentError, 'malformed ETF' if !skip_version_check && @data.getbyte != 131

      decode_term
    end

    def decode_term
      tag = @data.getbyte

      # check the tag to get the type of the term
      case tag
      when 80 then decompress_data
      when 97 then decode_byte
      when 98 then decode_int
      when 88 then decode_pid
      when 104 then decode_small_tuple
      when 105 then decode_large_tuple
      when 116 then decode_map
      # 106 is the tag for an empty list
      when 106 then []
      when 107 then decode_string
      when 108 then decode_list
      when 109 then decode_binary
      when 110 then decode_small_bigint
      when 111 then decode_large_bigint
      when 90 then decode_reference
      when 77 then decode_bit_binary
      when 118, 100 then decode_atom
      when 119, 115 then decode_small_atom
      else
        raise ArgumentError, "unknown or unimplemented tag: #{tag}"
      end
    end

    private

    def decompress_data
      uncompressed_size = @data.read(4).unpack1('N')
      compressed_data = @data.read
      str = Zlib::Inflate.inflate(compressed_data)

      raise ArgumentError, 'decompressed data is not the expected size' unless @data.size == uncompressed_size

      @data = StringIO.new(str).binmode
      decode_term
    end

    def decode_byte
      @data.getc.unpack1('C')
    end

    def decode_int
      @data.read(4).unpack1('N')
    end

    def decode_short_int
      @data.read(2).unpack1('n')
    end

    def decode_float
      @data.read(8).unpack1('G')
    end

    def decode_small_atom
      size = decode_byte
      str = @data.read(size).unpack1('a*')

      case str
        # special casing for the atoms true, false, and nil
      when 'true' then true
      when 'false' then false
      when 'nil' then nil
      else str.to_sym
      end
    end

    def decode_atom
      size = decode_short_int
      str = @data.read(size).unpack1('a*')

      case str
      # special casing for the atoms true, false, and nil
      when 'true' then true
      when 'false' then false
      when 'nil' then nil
      else str.to_sym
      end
    end

    def decode_small_tuple
      size = decode_byte
      result = Array.new(size) { decode_term }
      Tuple[*result]
    end

    def decode_large_tuple
      size = decode_int
      result = Array.new(size) { decode_term }
      Tuple[*result]
    end

    def decode_list
      size = decode_int
      result = []
      Array.new(size) { decode_term }

      # for erlang lists, if its a proper list
      # the last element will be an empty list
      # we should pop it off since we're using
      # Ruby arrays to represent Erlang lists
      result.pop if result.last == []

      result
    end

    def decode_binary
      size = decode_int
      @data.read(size).unpack1('a*')
    end

    # Even though its called a 'string'
    # its actually a list of integers
    # but we're decoding it as a Ruby string
    def decode_string
      size = decode_short_int
      @data.read(size).unpack1('U*')
    end

    def decode_reference
      size = decode_short_int
      node = decode_atom
      creation = decode_int

      id = Array.new(size) { decode_int }
      Reference.new(creation, id, node)
    end

    def decode_pid
      node = decode_atom
      id = decode_int
      serial = decode_int
      creation = decode_int
      PID.new(id, serial, creation, node)
    end

    def decode_bit_binary
      size = decode_int
      bits = decode_byte
      str = @data.read(size).unpack1('a*')
      BitBinary.new(str, bits)
    end

    def decode_map
      result = {}
      size = decode_int

      size.times do
        key = decode_term
        value = decode_term
        result[key] = value
      end

      return result unless result.key?(:__struct__)

      struct_name = result[:__struct__]

      return result unless struct_name.is_a?(Symbol)

      rubified_name = struct_name.to_s.delete_prefix('Elixir.').gsub('.', '::')

      return result unless Object.const_defined?(rubified_name)

      klass = Object.const_get(rubified_name)

      return result unless klass.respond_to?(:from_etf)

      klass.from_etf(result)
    end

    def decode_small_bigint
      size = decode_byte
      sign = decode_byte
      bytes = @data.read(size).unpack1('C*')

      num = bytes.reduce(0) { |acc, byte| (acc << 8) | byte }

      num = -num unless sign.zero?

      num
    end

    def decode_large_bigint
      size = decode_int
      sign = decode_byte
      bytes = @data.read(size).unpack1('C*')

      num = bytes.reduce(0) { |acc, byte| (acc << 8) | byte }

      num = -num unless sign.zero?

      num
    end
  end
end
