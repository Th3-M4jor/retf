# frozen_string_literal: true

module Retf
  # Represents Erlang tuples.
  #
  # They are basically frozen arrays with a fixed size.
  # Trying to access an index that is out of bounds
  # will raise an `IndexError`.
  class Tuple
    include Enumerable

    attr_reader :size, :value

    alias length size
    alias count size

    def self.[](...)
      new(...)
    end

    def initialize(*value)
      raise ArgumentError, 'size of tuple exceeds 4 byte integer limit' if value.size > ::Retf::USIZE_MAX

      @value = value.freeze
      @size = value.size
    end

    def each(&)
      value.each(&)
    end

    def to_etf
      prefix = if size < 256
                 [104, size].pack('CC')
               else
                 [105, size].pack('CN')
               end

      prefix << (value.map(&:to_etf).join)
    end

    def to_s
      value.to_s
    end

    def to_a
      value.dup
    end

    def ==(other)
      other.is_a?(Tuple) &&
        value == other.value
    end

    def [](index)
      raise IndexError, "index #{index} out of bounds" if index >= @size

      value[index]
    end

    def inspect
      "#Tuple{#{value.map(&:inspect).join(', ')}}"
    end

    def deconstruct
      value
    end
  end
end
