# frozen_string_literal: true

module Retf
  # Represents an Erlang bitstring which
  # does not fit cleanly into a multiple of 8 bits.
  class BitBinary
    attr_reader :binary, :bits_size

    def initialize(binary, bits_size)
      @binary = binary
      @bits_size = bits_size
    end

    def to_etf
      [77, binary.bytesize, bits_size, binary].pack('CNCa*')
    end

    def ==(other)
      other.is_a?(BitBinary) &&
        @bits == other.bits &&
        @binary == other.binary
    end

    def to_s
      inspected_bin = @binary.join(', ')
      "<<#{inspected_bin}, #{@bits}::size(#{@bits_size})>>"
    end

    alias inspect to_s
  end
end
