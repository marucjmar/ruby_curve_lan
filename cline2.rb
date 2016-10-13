require "socket"
require 'json'

class Client
  def initialize( server )
    @server = server
    @request = nil
    @response = nil
    listen
    send
    @request.join
    @response.join
  end
 
  def listen
    @response = Thread.new do
      loop {
        msg = @server.gets.split('|')
        puts msg[0]
      }
    end
  end
 
  def send
    puts "Enter the username:"
    @request = Thread.new do
        msg = $stdin.gets.chomp
        @server.puts( msg )
    end
  end
end
 
server = TCPSocket.open( "localhost", 300 )
Client.new( server )