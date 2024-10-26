# frozen_string_literal: true

require_relative 'retf/bit_binary'

# IO::Buffer may not be available in all Ruby versions
# that we should support so if it is not available
# we will use a fallback decoder that is a bit slower
# and uses StringIO instead.
if defined?(IO::Buffer)
  require_relative 'retf/decoder'
else
  require_relative 'retf/decoder_fallback'
end

require_relative 'retf/encoder'
# require_relative 'retf/encoding'
require_relative 'retf/pid'
require_relative 'retf/reference'
require_relative 'retf/tuple'

# Retf is a pure Ruby library for encoding and decoding
# Erlang External Term Format (ETF) values.
#
# See the README for usage and compatibility information.
module Retf
  USIZE_MAX = 4_294_967_295 # :nodoc:

  ISIZE_MAX = 2_147_483_647 # :nodoc:

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
      # Encoder.new(value, compress:).encode
      ::Retf::Native.encode(value, compress)
    end

    alias dump encode
    alias serialize encode

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
    #
    # WARNING: For performance reasons, the given
    # string may be modified in place or frozen.
    # If you wish to re-use given string,
    # you should pass a copy of it to this method
    # instead.
    # @param value [String] the binary string to decode
    def decode(value)
      ::Retf::Native.decode(value, false)
      # Decoder.new(value.freeze).decode(skip_version_check: false)
    end

    alias load decode
    alias deserialize decode
  end
end

require_relative 'retf/retf_native'
