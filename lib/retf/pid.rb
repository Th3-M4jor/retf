# frozen_string_literal: true

module Retf
  # Represents an Erlang PID.
  # Though documented for completeness,
  # the contents of this class should be
  # considered opaque.
  #
  # @param node [String] the node name
  # @param id [Integer] the process ID
  # @param serial [Integer] the message serial number
  # @param creation [Integer] the creation number
  class PID
    attr_reader :node, :id, :serial, :creation

    def initialize(id, serial, creation, node = :'nonode@nohost')
      @node = node
      @id = id
      @serial = serial
      @creation = creation
    end

    def to_etf
      encoded_node = @node.to_etf

      # 88 is the tag for a PID
      [88, encoded_node, id, serial, creation].pack('Ca*NNN')
    end

    def to_s
      "#PID<#{@node} : #{@id}.#{@serial}.#{@creation}>"
    end

    alias inspect to_s

    def ==(other)
      other.is_a?(PID) &&
        @node == other.node &&
        @id == other.id &&
        @serial == other.serial &&
        @creation == other.creation
    end
  end
end
