# frozen_string_literal: true

require_relative 'retf/bit_binary'
require_relative 'retf/decoder'
require_relative 'retf/encoder'
require_relative 'retf/encoding'
require_relative 'retf/pid'
require_relative 'retf/reference'
require_relative 'retf/tuple'

# Retf is a pure Ruby library for encoding and decoding
# Erlang External Term Format (ETF) values.
#
# See the README for usage and compatibility information.
module Retf
  # Maximum value for a 32-bit unsigned integer
  USIZE_MAX = 4_294_967_295 # :nodoc:

  # Maximum value for a 32-bit signed integer
  ISIZE_MAX = 2_147_483_647 # :nodoc:

  # Minimum value for a 32-bit signed integer
  ISIZE_MIN = -2_147_483_648 # :nodoc:

  class << self
    # Encodes a given value into a binary string
    # that can be sent to an Erlang node.
    #
    # Raises TypeError if given value cannot be encoded.
    #
    # Classes can define their own encoding by
    # defining an `#as_etf` method.
    # This method should return an unfrozen `Hash`
    # with the classes state encoded
    # into it.
    #
    # The keys of the hash are expected to be
    # symbols and the returned Hash will be
    # modified to include a `:__struct__` key
    # set to the name of the class except
    # with "::" replaced by "." and
    # prefixed with "Elixir." so that
    # an Elixir struct can be mapped to
    # the Ruby class.
    #
    #
    # @param value [Object] the value to encode
    # @option compress [Boolean] whether to Gzip compress the encoded value
    # @return [String] the encoded value
    def encode(value, compress: false)
      Encoder.new(value, compress:).encode
    end

    # Decodes a binary string into a Ruby object.
    # Raises TypeError if the given binary string
    # cannot be decoded.
    #
    # If a Map is decoded and said hash has a
    # `:__struct__` key which maps to a sympol,
    # a Class with the same name will have its
    # `.from_etf` method called
    # and passed the hash.
    #
    # If the Class does not exist
    # or does not respond to `.from_etf`,
    # the hash will be returned as is.
    def decode(value)
      Decoder.new(value).decode
    end
  end
end
