# frozen_string_literal: true

require 'zlib'

module Retf
  class Decoder # :nodoc:
    def initialize(data)
      @data = IO::Buffer.for(data.freeze)
      @offset = 0
    end

    def decode(skip_version_check:)
      raise ArgumentError, 'malformed ETF' if !skip_version_check && decode_byte != 131

      begin
        decode_term
      ensure
        @data.free
        @data = nil
      end
    end

    private

    def decode_term
      tag = decode_byte

      # While Ruby cannot do much to optimize
      # long case statements like this and
      # has to check each case in order,
      # we can at least group similar tags
      # and order them in a way that makes
      # the ones which are probably more common
      # in practice come first.
      #
      # Tried to optimize this to a jump table
      # using an array of procs but it was slower
      # with the yjit enabled... which??????
      case tag
      when 118, 100 then decode_atom
      when 119, 115 then decode_small_atom
      when 109 then decode_binary
      when 97 then decode_byte
      when 98 then decode_signed_int
      when 116 then decode_map
      when 104 then decode_small_tuple
      when 70 then decode_float
      when 108 then decode_list
      when 106 then [] # empty list tag
      when 107 then decode_string
      when 110 then decode_small_bigint
      when 111 then decode_large_bigint
      when 88 then decode_pid
      when 90 then decode_reference
      when 105 then decode_large_tuple
      when 77 then decode_bit_binary
      when 80 then decompress_data
      else
        raise ArgumentError, "unknown or unimplemented tag: #{tag}"
      end
    end

    def decompress_data
      uncompressed_size = decode_int
      compressed_data = @data.get_string(@offset)
      str = Zlib::Inflate.inflate(compressed_data)

      # By freezing the string we can avoid
      # the IO::Buffer class from copying the
      # string when it initializes the buffer
      str.freeze

      raise ArgumentError, 'decompressed data is not the expected size' unless str.bytesize == uncompressed_size

      @data.free
      @offset = 0

      @data = IO::Buffer.for(str)
      decode_term
    end

    def decode_any_atom
      tag = decode_byte

      case tag
      when 119, 115 then decode_small_atom
      when 118, 100 then decode_atom
      else
        raise ArgumentError, "expected an atom tag, got #{tag}"
      end
    end

    def decode_byte
      value = @data.get_value(:U8, @offset)
      @offset += 1
      value
    end

    def decode_signed_int
      value = @data.get_value(:S32, @offset)
      @offset += 4
      value
    end

    def decode_int
      value = @data.get_value(:U32, @offset)
      @offset += 4
      value
    end

    def decode_short_int
      value = @data.get_value(:U16, @offset)
      @offset += 2
      value
    end

    def decode_float
      value = @data.get_value(:F64, @offset)
      @offset += 8
      value
    end

    def decode_small_atom
      size = decode_byte
      str = @data.get_string(@offset, size)
      @offset += size

      case str
      # special casing for the atoms true, false, and nil
      when 'true' then true
      when 'false' then false
      when 'nil' then nil
      else
        symbolize(str)
      end
    end

    def decode_atom
      size = decode_short_int
      str = @data.get_string(@offset, size)
      @offset += size

      case str
      # special casing for the atoms true, false, and nil
      when 'true' then true
      when 'false' then false
      when 'nil' then nil
      else
        symbolize(str)
      end
    end

    def symbolize(str)
      # all atoms are expected to be UTF-8 encoded
      str.force_encoding(Encoding::UTF_8)

      return str.to_sym unless str.start_with?('Elixir.')

      val = str.delete_prefix('Elixir.').gsub('.', '::')

      return str.to_sym unless Object.const_defined?(val)

      Object.const_get(val)
    end

    def decode_small_tuple
      size = decode_byte
      result = Array.new(size) { decode_term }
      Tuple.from_array(result)
    end

    def decode_large_tuple
      size = decode_int
      result = Array.new(size) { decode_term }
      Tuple.from_array(result)
    end

    def decode_list
      # length does not include the tail
      size = decode_int + 1
      result = Array.new(size) { decode_term }

      # for erlang lists, if its a proper list
      # the last element will be an empty list
      # we should pop it off since we're using
      # Ruby arrays to represent Erlang lists
      result.pop if result.last == []

      result
    end

    def decode_binary
      size = decode_int
      value = @data.get_string(@offset, size)
      @offset += size
      value
    end

    # Even though its called a 'string'
    # its actually a list of bytes
    # we'll decode it as an array
    # and let the user decide how to
    # handle it
    def decode_string
      size = decode_short_int

      value = @data.get_string(@offset, size).bytes
      @offset += size
      value
    end

    def decode_reference
      size = decode_short_int
      node = decode_any_atom
      creation = decode_int

      id = Array.new(size) { decode_int }
      Reference.new(creation, id, node)
    end

    def decode_pid
      node = decode_any_atom
      id = decode_int
      serial = decode_int
      creation = decode_int
      PID.new(id, serial, creation, node)
    end

    def decode_bit_binary
      size = decode_int
      bits = decode_byte

      str = @data.get_string(@offset, size)
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

      # Whatever was stored here does not respond to from_etf
      # so lets just return the result as is.
      #
      # The decode_atom method handles attempting to
      # constantize something that looks like it could be
      # a class name.
      return result unless struct_name.respond_to?(:from_etf)

      struct_name.from_etf(result)
    end

    def decode_small_bigint
      size = decode_byte
      sign = decode_byte

      bytes = @data.get_string(@offset, size).bytes

      @offset += size

      num = 0

      bytes.each_with_index do |byte, idx|
        num += (byte * (256**idx))
      end

      num = -num unless sign.zero?

      num
    end

    def decode_large_bigint
      size = decode_int
      sign = decode_byte

      bytes = @data.get_string(@offset, size).bytes

      @offset += size

      num = 0

      bytes.each_with_index do |byte, idx|
        num += (byte * (256**idx))
      end

      num = -num unless sign.zero?

      num
    end
  end
end
