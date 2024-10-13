# frozen_string_literal: true

require 'retf'

RSpec.describe Retf::BitBinary do
  it 'decodes a single byte bit binary' do
    encoded = [131, 77, 1, 4, 0xF0].pack('CCNCC')

    expect(Retf.decode(encoded)).to eq(described_class.new("\xF0", 4))
  end

  it 'decodes a multi byte bit binary' do
    encoded = [131, 77, 2, 4, 0x42, 0xE0].pack('CCNCCC')

    expect(Retf.decode(encoded)).to eq(described_class.new("\x42\xE0", 4))
  end
end
