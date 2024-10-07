# frozen_string_literal: true

# This file contains monkey patches to add
# etf enocding to basic Ruby objects

class Object # :nodoc:
  def to_etf
    raise ArgumentError, 'Object does not support etf encoding' unless respond_to?(:as_etf)

    result = as_etf

    raise TypeError, 'expected a Has to be returned' unless result.is_a?(Hash)

    result[:__struct__] = symbolize_class_name
    result.to_etf
  end

  private

  def etf_encode_class_name
    # replaces "::" with "." and converts to a symbol
    # then prepends "Elixir." to match Elixir's module naming convention
    str = 'Elixir.' + self.class.name.gsub('::', '.') # rubocop:disable Style/StringConcatenation

    raise ArgumentError, 'class name is too long, must be less than 255 characters' if str.length > 255

    if str.bytesize < 256
      # 119 is the SMALL_ATOM_EXT tag
      [119, str.bytesize, str].pack('CCa*')
    else
      # 118 is the ATOM_EXT tag
      [118, str.bytesize, str].pack('Cna*')
    end
  end
end

class NilClass # :nodoc:
  def to_etf
    # This is the output of
    # [119, 3, "nil"].pack("CCa*")
    #
    # 119 is the SMALL_ATOM_EXT tag
    # 3 is the length of the atom
    # "nil" is string representation of the atom
    +"w\x03nil"
  end
end

class FalseClass # :nodoc:
  def to_etf
    +"w\x05false"
  end
end

class TrueClass # :nodoc:
  def to_etf
    +"w\x04true"
  end
end

class Integer # :nodoc:
  def to_etf
    # unsigned 8-bit integer
    if self >= 0 && self < 256
      [97, self].pack('CC')
    # signed 32-bit integer
    elsif self >= ::Retf::ISIZE_MIN && self <= ::Retf::ISIZE_MAX
      [98, self].pack('Cl>')
    else
      large_etf_encode
    end
  end

  private

  def large_etf_encode
    # Large integer encoding
    # The format is:
    #  tag, n, sign, bytes
    #
    # 110 is the SMALL_BIG_EXT tag
    # 111 is the LARGE_BIG_EXT tag
    #
    # For SMALL_BIG_EXT n is 1 byte in size
    # For LARGE_BIG_EXT n is 4 bytes in size
    # sign is 0 for positive and 1 for negative
    # bytes is the integer encoded in little endian
    # format, and must support an arbitrary number of bytes
    # so we use the `digits(256)` method to get the
    # digits of the number in base 256 and then pack
    # them into a binary string, then pack that into
    # the final binary string

    sign = negative? ? 1 : 0

    digit_array = abs.digits(256)

    len = digit_array.size

    packed_digits = digit_array.pack('C*')

    if len < 256
      [110, len, sign, packed_digits].pack('CCCa*')
    else
      [111, len, sign, packed_digits].pack('CNCa*')
    end
  end
end

class Float # :nodoc:
  def to_etf
    # ETF specifies that NaN and Infinity are not supported
    # therefore we raise an error if the float is not finite
    raise TypeError, 'only finite floats are supported' unless finite?

    # 70 is the NEW_FLOAT_EXT tag
    # and the float is encoded as a Big Endian 64-bit float
    [70, self].pack('CG')
  end
end

class String # :nodoc:
  def to_etf
    if bytesize > ::Retf::USIZE_MAX
      raise ArgumentError, 'string is too large to encode, size must fit in a 32-bit unsigned integer'
    end

    [109, bytesize, self].pack('CNa*')
  end
end

class Array # :nodoc:
  def to_etf
    # if the array is empty, we return the NIL_EXT tag
    # which makes it an empty list
    return +'j' if empty?

    if size > ::Retf::USIZE_MAX
      raise ArgumentError,
            'array is too large to encode, size must fit in a 32-bit unsigned integer'
    end

    objs = map(&:to_etf).join

    # 108 is the LIST_EXT tag
    # n is the size of the list
    # objs is the encoded objects in the list
    # 106 or 'j' is the NIL_EXT tag
    # which makes it a proper list
    [108, size, objs].pack('CNa*') << 'j'
  end
end

class Hash # :nodoc:
  def to_etf
    if size > ::Retf::USIZE_MAX
      raise ArgumentError,
            'hash is too large to encode, size must fit in a 32-bit unsigned integer'
    end

    values = map do |key, value|
      key.to_etf << value.to_etf
    end

    # 116 is the MAP_EXT tag
    # n is the size of the map
    # values is the encoded key-value pairs
    [116, size, values.join].pack('CNa*')
  end
end

class Symbol # :nodoc:
  def to_etf
    raise ArgumentError, 'symbol name is too long, must be less than 255 characters' if name.length > 255

    if name.bytesize < 256
      [119, name.bytesize, name].pack('CCa*')
    else
      [118, name.bytesize, name].pack('Cna*')
    end
  end
end
