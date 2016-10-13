
require 'rubygems'
require 'rubygame'
require 'socket'
require 'json'
include Rubygame

class Cube
	attr_writer :x, :y
	attr_reader :x, :y, :color, :size, :y_vector,:x_vector, :id
	def initialize(color, id, x,y)
		@x = x
		@y = y
		@size = 5
		@id = id
		@color = color
		@x_vector = 1
		@y_vector = 0
		@speed = 1
	end

	def to_left
		if @x > 1 and @y_vector == 0
			@y_vector = -1
			@x_vector = 0
		elsif @x < 0 and @y_vector == 0
			@y_vector = 1
			@x_vector = 0
		elsif @y < 0 and @x_vector == 0
			@x_vector = 1
			@y_vector = 0
		elsif @y > 0 and @x_vector == 0
			@x_vector = -1
			@y_vector = 0
		end
	end

	def to_right
		if @x > 1 and @y_vector == 0
			@y_vector = 1
			@x_vector = 0
		elsif @x < 0 and @y_vector == 0
			@y_vector = -1
			@x_vector = 0
		elsif @y > 0 and @x_vector == 0
			@x_vector = 1
			@y_vector = 0
		elsif @y < 0 and @x_vector == 0
			@x_vector = -1
			@y_vector = 0
		end
	end

	def update_position
		@x += @x_vector * @speed
		@y += @y_vector	* @speed
	end
end



class Game
  def initialize
  	@u1 = UDPSocket.new
		@u1.connect("192.168.1.3",122)
		register_player

		sleep(1)
    @player
    @guest = []

    @screen = Rubygame::Screen.new [840,680], 0, [Rubygame::HWSURFACE, Rubygame::DOUBLEBUF]
    @screen.title = "Generic Game!"
    @queue = Rubygame::EventQueue.new
    @clock = Rubygame::Clock.new
    @clock.target_framerate = 30

    @colors = ["red", "green", "blue", "yellow"]
	
  end

  def register_player
		@u1.send("register",0,"192.168.1.3",122 )
		data = JSON.parse(@u1.recvfrom(1024)[0])
		@player = Cube.new(1,data['id'],33,33)
  end

  def get_data_server
        data =  JSON.parse(@u1.recvfrom(1024)[0])
        puts data
        case data[0]
        	when "new_guest"
        		puts data[2]
        		puts data[3]
        		@guest.push(Cube.new(data[2].to_i, data[1],data[3].to_i,data[4].to_i))
      	end
  end

  def run
    loop do
    	send_my_position
    	get_data_server
      @player.update_position
      update
      draw
      collision
      @clock.tick
    end
  end

  def key_event(key)
		case key
	    	when Rubygame::K_LEFT
	    	  @player.to_left
	      when K_RIGHT
	    	  @player.to_right
	  end
  end

  def send_my_direction(direct)
  	Thread.new do
        @server.puts("direction|#{@player.id}|#{direct}")
    end
  end

  def send_my_position
  		data = {player: @player.id,x:@player.x, y:@player.y}.to_json
      @u1.send data,0,"192.168.1.3",122
  end

  def change_position(id,x,y)
  	@guest.each do |guest|
  		if guest.id == id
  			guest.x = x.to_i
  			guest.y = y.to_i
  		end
  	end
  end

  def change_guest_direction(id, direction)
  	@guest.each do |guest|
  		if guest.id == id
  			case  direction
  				when "1"
  					guest.to_left
  				else
  					guest.to_right
  			end
  		end
  	end
  end

  def update
    @queue.each do |ev|
      case ev
        when Rubygame::QuitEvent
          Rubygame.quit
          exit
        when Rubygame::KeyDownEvent
        	key_event(ev.key)
      end
    end
  end

  def draw
  	@screen.draw_box_s(
			[@player.x,@player.y],
			[@player.x+@player.size, @player.y+@player.size], 
			@colors[@player.color])
	  	@guest.each do |guest|
				@screen.draw_box_s(
							[guest.x,guest.y],
							[guest.x+guest.size, guest.y+guest.size], 
							@colors[guest.color])
	  	end

    @screen.update
  end

  def collision
  	if @player.x_vector > 0 and @player.y_vector == 0
		color = @screen.get_at(@player.x+@player.size+1, @player.y+@player.size/2)
	elsif @player.x_vector < 0 and @player.y_vector == 0
		color = @screen.get_at(@player.x-1, @player.y+@player.size/2)
	elsif @player.x_vector == 0 and @player.y_vector > 0
		color = @screen.get_at(@player.x+@player.size/2, @player.y+@player.size+1)
	elsif @player.x_vector == 0 and @player.y_vector < 0
		color = @screen.get_at(@player.x+@player.size/2, @player.y-1)
  	end
  	
  	unless color[0] == 0 and color[1] == 0 and color[2] == 0 and color[3] == 255
  		puts "Przegrales"
  	end	
  		
  end
end

game = Game.new
game.run