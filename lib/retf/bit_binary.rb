# frozen_string_literal: true

module Retf
  # Represents an Erlang bitstring which
  # does not fit cleanly into a multiple of 8 bits.
  class BitBinary
    attr_reader :binary, :bits_size

    def initialize(binary, bits_size)
      @binary = binary.b
      @bits_size = bits_size
    end

    def to_etf(buffer)
      buffer << [77, binary.bytesize, bits_size].pack('CNC')

      buffer << binary
    end

    def ==(other)
      other.is_a?(BitBinary) &&
        @bits_size == other.bits_size &&
        @binary == other.binary
    end

    def to_s
      "#BitBinary<#{binary.inspect}, #{bits_size}>"
    end

    alias inspect to_s
  end
end
