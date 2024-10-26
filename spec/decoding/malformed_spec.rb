# frozen_string_literal: true

require 'retf'

RSpec.describe 'Malformed ETF' do
  it 'raises an error when the version is not 131' do
    encoded = [130].pack('C')

    expect { Retf.decode(encoded) }.to raise_error(ArgumentError, 'malformed ETF')
  end

  it 'raises an error when a tag is not recognized' do
    encoded = [131, 0].pack('CC')

    expect { Retf.decode(encoded) }.to raise_error(ArgumentError, 'unexpected tag: 0')
  end

  it 'raises an error when it unexpectedly reaches the end of the encoded data' do
    encoded = [131, 97].pack('CC')

    expect { Retf.decode(encoded) }.to raise_error(ArgumentError, 'Unexpected end of input')
  end
end
