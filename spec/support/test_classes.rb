# frozen_string_literal: true

module Test
  class MyClass
    attr_accessor :a, :b

    def initialize(first, second)
      self.a = first
      self.b = second
    end

    def ==(other)
      a == other.a && b == other.b
    end

    def as_etf
      { a:, b: }
    end

    def self.from_etf(value)
      new(value[:a], value[:b])
    end
  end

  class MyOtherClass
    attr_accessor :a, :b

    def initialize(first = nil, second = nil)
      self.a = first
      self.b = second
    end
  end
end
