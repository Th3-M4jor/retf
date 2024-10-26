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

    def to_etf(buffer = ''.b)
      buffer << [88].pack('C')

      @node.to_etf(buffer)

      # 88 is the tag for a PID
      buffer << [id, serial, creation].pack('NNN')
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
