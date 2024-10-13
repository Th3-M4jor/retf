# frozen_string_literal: true

require 'retf'

RSpec.describe Float do
  it 'encodes a float' do
    float = 3.14

    encoded = Retf.encode(float)

    expect(encoded.bytes).to eq([131, 70, 64, 9, 30, 184, 81, 235, 133, 31])
  end

  it 'encodes a negative float' do
    float = -3.14

    encoded = Retf.encode(float)

    expect(encoded.bytes).to eq([131, 70, 192, 9, 30, 184, 81, 235, 133, 31])
  end

  it 'encodes a float with a value of 0' do
    float = 0.0

    encoded = Retf.encode(float)

    expect(encoded.bytes).to eq([131, 70, 0, 0, 0, 0, 0, 0, 0, 0])
  end

  it 'encodes a float with a value of negative 0' do
    float = -0.0

    encoded = Retf.encode(float)

    expect(encoded.bytes).to eq([131, 70, 128, 0, 0, 0, 0, 0, 0, 0])
  end

  it 'raises an error when encoding positive infinity' do
    float = Float::INFINITY

    expect do
      Retf.encode(float)
    end.to raise_error(ArgumentError, 'only floats with a finite value can be encoded')
  end

  it 'raises an error when encoding negative infinity' do
    float = -Float::INFINITY

    expect do
      Retf.encode(float)
    end.to raise_error(ArgumentError, 'only floats with a finite value can be encoded')
  end

  it 'raises an error when encoding NaN' do
    float = Float::NAN

    expect do
      Retf.encode(float)
    end.to raise_error(ArgumentError, 'only floats with a finite value can be encoded')
  end
end
