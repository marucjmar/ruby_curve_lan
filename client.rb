require 'socket'
require 'json'
require 'thread'

@host = "192.168.1.3"
@port = 80
BasicSocket.do_not_reverse_lookup = true
# Create socket and bind to address
@socket = UDPSocket.new
@socket.setsockopt(Socket::SOL_SOCKET,Socket::SO_BROADCAST, 0)
@socket.bind(@host, @port)
@clientPorts = []


def broadcast(data, clients)                 
  clients.each do |client|
    @socket.send(data, 0, @host, client)
  end
end

def register_player(clientAddress)
  data = {id:clientAddress,color: 1}.to_json
end

while true
  data, client = @socket.recvfrom(1024)
  puts client.inspect
  Thread.new(client) do |clientAddress|
    if data == "register"
      data = register_player(clientAddress[1])
      register_guest = {event: 'add_guest',spec: data}
      @clientPorts.each do |client|
        @socket.send(register_guest, 0, @host, client)
      end
    end
    unless @clientPorts.include? clientAddress[1]
      @clientPorts << clientAddress[1]
    end
    broadcast(data, @clientPorts)
  end
  puts @clientPorts.length
end