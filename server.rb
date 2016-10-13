require "socket"
require 'json'

class Server
  def initialize( port, ip )
    @server = TCPServer.open( ip, port )
    @connections = Hash.new
    @clients = Hash.new
    @connections[:server] = @server
    @connections[:rooms] = @rooms
    @connections[:clients] = @clients
    run
  end
 
  def generate_id
  	(0..9).map { ('a'..'z').to_a[rand(25)] }.join
  end

  def generate_color
  	(0...4).to_a.sample
  end

  def run
    loop {
      Thread.start(@server.accept) do | client |
        nick_name = generate_id
        color = generate_color
        client.puts "registry|#{nick_name}|#{color}|#{rand(640)}|#{rand(480)}"
        @connections[:clients].each do |other_name,other_client|
	        other_client.puts "guest|#{nick_name}|#{color}"
        end
        @connections[:clients][nick_name] = client
        listen_user_messages( nick_name, client )
      end
    }.join
  end
 
  def listen_user_messages( username, client )
    loop {
      msg = client.gets
      @connections[:clients].each do |other_name, other_client|
          other_client.puts(msg)
      end
    }
  end
end
 
Server.new( 300, "localhost" )