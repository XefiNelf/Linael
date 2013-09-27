require 'message_struct.rb'
require 'message_fifo.rb'

module Linael
  class SocketList

    include Enumerable

    attr_accessor :sockets

    def initialize
      @sockets = []      
      @fifo = MessageFifo.instance
    end

    def each
      @servers.each
    end

    def add klass,options
      options[name] ||= options[url] + options[port]to_s
      raise Exception, "Allready used name" if servers.detect {|s| s.name == name}
      @servers << klass.new(options)
      name
    end

    def connect name
      server_by_name(name).listen
    end

    def remove name
      @servers = @servers.delete_if {|s| s.name == name}
    end

    def [](name)
      raise Exception, "No server." if servers.empty?
      return servers[0] unless name
      result = servers.detect {|s| s.name == name}
      raise Exception, "No server with this name (#{name})." unless result
      result
    end

    alias_method :server_by_name, :[]

    def send_msg(msg)
      server_by_name(msg.server_name).puts(msg.element)
    end

    def gets
      @fifo.gets
    end

  end
end
