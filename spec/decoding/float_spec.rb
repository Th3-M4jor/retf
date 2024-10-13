# frozen_string_literal: true

require 'retf'

RSpec.describe Float do
  it 'decodes a float' do
    float = 3.14

    encoded = [131, 70, 64, 9, 30, 184, 81, 235, 133, 31].pack('C*')

    expect(Retf.decode(encoded)).to eq float
  end

  it 'decodes a negative float' do
    float = -3.14

    encoded = [131, 70, 192, 9, 30, 184, 81, 235, 133, 31].pack('C*')

    expect(Retf.decode(encoded)).to eq float
  end

  it 'decodes a float with a value of 0' do
    float = 0.0

    encoded = [131, 70, 0, 0, 0, 0, 0, 0, 0, 0].pack('C*')

    expect(Retf.decode(encoded)).to eq float
  end

  it 'decodes negative zero' do
    float = -0.0

    encoded = [131, 70, 128, 0, 0, 0, 0, 0, 0, 0].pack('C*')

    expect(Retf.decode(encoded)).to eq float
  end

  it 'decodes positive infinity' do
    # This isn't supported by the BEAM, but we'll
    # support decoding it for ease of implementation
    float = Float::INFINITY

    encoded = [131, 70, 127, 240, 0, 0, 0, 0, 0, 0].pack('C*')

    expect(Retf.decode(encoded)).to eq float
  end

  it 'decodes negative infinity' do
    # This isn't supported by the BEAM, but we'll
    # support decoding it for ease of implementation
    float = -Float::INFINITY

    encoded = [131, 70, 255, 240, 0, 0, 0, 0, 0, 0].pack('C*')

    expect(Retf.decode(encoded)).to eq float
  end

  it 'decodes NaN' do
    # This isn't supported by the BEAM, but we'll
    # support decoding it for ease of implementation
    encoded = [131, 70, 127, 248, 0, 0, 0, 0, 0, 0].pack('C*')

    expect(Retf.decode(encoded)).to be_nan
  end
end
