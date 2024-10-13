# frozen_string_literal: true

require 'retf'

RSpec.describe Retf::PID do
  it 'decodes a PID' do
    encoded = [131, 88, 119, 13, 110, 111, 110, 111, 100, 101, 64, 110, 111, 104, 111, 115,
               116, 0, 0, 0, 105, 0, 0, 0, 0, 0, 0, 0, 0].pack('C*')

    expected_pid = described_class.new(105, 0, 0, :'nonode@nohost')

    expect(Retf.decode(encoded)).to eq(expected_pid)
  end
end
