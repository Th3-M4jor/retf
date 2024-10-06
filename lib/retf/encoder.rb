# frozen_string_literal: true

require 'zlib'
require 'stringio'

module Retf
  class Encoder # :nodoc:
    def initialize(value, compress:)
      @value = value
      @compress = compress
    end

    def encode
      result = @value.to_etf

      # If the etf is to be compressed, we need
      # to tag it with the compressed tag
      # followed by the uncompressed size
      # and the compressed data
      if @compress
        # uncompressed size is the size of the data
        # minus the initial tag byte?
        uncompressed_size = result.size - 1
        result = compress(result)
        [131, 80, uncompressed_size, result].pack('CCNa*')
      else
        [131, result].pack('Ca*')
      end
    end

    private

    def compress(data)
      output = Stream.new
      gz = Zlib::GzipWriter.new(output, Zlib::DEFAULT_COMPRESSION, Zlib::DEFAULT_STRATEGY)
      gz.write(data)
      gz.close
      output.string
    end
  end
end
