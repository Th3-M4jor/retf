# frozen_string_literal: true

module Retf
  # Represents an Erlang reference.
  # Though documented for completeness,
  # the contents of this class should be
  # considered opaque, similar to `Retf::PID`.
  #
  # @param creation [Integer] the creation number
  # @param id [Array<Integer>] the reference ID
  # @param node [String] the node name
  class Reference
    attr_reader :node, :creation, :id

    def initialize(creation, id, node = :'nonode@nohost')
      @node = node
      @creation = creation
      @id = id
    end

    def ==(other)
      other.is_a?(Reference) &&
        @node == other.node &&
        @id == other.id &&
        @creation == other.creation
    end

    def to_etf(buffer = ''.b)
      buffer << [90, @id.size].pack('Cn')
      @node.to_etf(buffer)

      buffer << [creation, *@id].pack('NN*')
    end

    def to_s
      "#Ref<#{node} : #{creation}.#{id}>"
    end

    alias inspect to_s
  end
end
