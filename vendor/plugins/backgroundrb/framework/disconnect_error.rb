module Packet
  class DisconnectError < RuntimeError
    attr_accessor :disconnected_socket
    def initialize(t_sock)
      @disconnected_socket = t_sock
    end
  end
end
