# frozen_string_literal: true

require 'retf'

RSpec.describe Symbol do
  describe 'small atoms' do
    it 'decodes a symbol' do
      symbol = 'hello'

      encoded = [131, 119, symbol.bytesize, symbol].pack('CCCa*')

      expect(Retf.decode(encoded)).to eq :hello
    end

    it 'decodes a symbol that needs to be quoted' do
      symbol = 'hello world'

      encoded = [131, 119, symbol.bytesize, symbol].pack('CCCa*')

      expect(Retf.decode(encoded)).to eq :'hello world'
    end

    it 'decodes a symbol that is an operator' do
      symbol = '=='

      encoded = [131, 119, symbol.bytesize, symbol].pack('CCCa*')

      expect(Retf.decode(encoded)).to eq :==
    end

    it 'decodes a symbol that is an empty string' do
      symbol = ''

      encoded = [131, 119, symbol.bytesize, symbol].pack('CCCa*')

      expect(Retf.decode(encoded)).to eq :''
    end
  end

  describe 'large atoms' do
    it 'decodes a symbol' do
      symbol = 'hello'

      encoded = [131, 118, symbol.bytesize, symbol].pack('CCna*')

      expect(Retf.decode(encoded)).to eq :hello
    end

    it 'decodes a symbol that includes utf-8 characters' do
      symbol = 'hello, 世界'

      encoded = [131, 118, symbol.bytesize, symbol].pack('CCna*')

      expect(Retf.decode(encoded)).to eq :'hello, 世界'
    end
  end

  it 'decodes the atom :nil as nil' do
    encoded = [131, 119, 3, 'nil'].pack('CCCa*')

    expect(Retf.decode(encoded)).to be_nil
  end

  it 'decodes the atom :true as true' do
    encoded = [131, 119, 4, 'true'].pack('CCCa*')

    expect(Retf.decode(encoded)).to be true
  end

  it 'decodes the atom :false as false' do
    encoded = [131, 119, 5, 'false'].pack('CCCa*')

    expect(Retf.decode(encoded)).to be false
  end

  it 'attempts to constantize atoms that look like class names' do
    str = 'Elixir.String'

    encoded = [131, 119, str.bytesize, str].pack('CCCa*')

    expect(Retf.decode(encoded)).to eq String
  end

  it 'returns the atom as a symbol if the constant does not exist' do
    str = 'Elixir.Foo'

    encoded = [131, 119, str.bytesize, str].pack('CCCa*')

    expect(Retf.decode(encoded)).to eq :'Elixir.Foo'
  end
end
