require 'gosu'
require './client'
require "socket"
require "json"



class Player
  attr_reader :x, :y, :angle
  def initialize(window)
    @image = Gosu::Image.new(window, "media/player.png", false)
    @x = @y = @vel_x = @vel_y = @angle = 0.0
    @score = 0
  end

  def warp(x, y)
    @x, @y = x, y
  end

  def turn_left
    @angle -= 4.5
  end

  def turn_right
    @angle += 4.5
  end

  def accelerate
    @vel_x += Gosu::offset_x(@angle, 0.5)
    @vel_y += Gosu::offset_y(@angle, 0.5)
  end

  def move
    unless @x + @vel_x > 640 or @x + @vel_x < 0
      @x += @vel_x
      @x %= 640
      @vel_x *= 0.95
    end

    unless @y + @vel_y > 480 or @y + @vel_y < 0 
      @y += @vel_y
      @y %= 480
      @vel_y *= 0.95
    end
  end


  def draw
    @image.draw_rot(@x, @y, 1, @angle)
  end

  

end

class PlayerGuest
  attr_writer :x, :y,:angle
attr_reader :x, :y,:angle
  def initialize(window)
    @image = Gosu::Image.new(window, "media/player.png", false)
    @x = 0
    @angle = 0
    @y = 0
  end

  def warp(x, y)
    @x, @y = x, y
  end

  def draw
    @image.draw_rot(@x, @y, 1, @angle)
  end
end

class GameWindow < Gosu::Window
  def initialize
    super(640, 480, false)
    self.caption = "Gosu Tutorial Game"
    @player = Player.new(self)
    @guest = PlayerGuest.new(self)
    @guest.warp(32, 240)
    @player.warp(320, 240)
    @server = TCPSocket.open( "localhost", 300 )
    @request = nil
    @response = nil
    send_id
  end

  def send_id
      @request = Thread.new do
        msg = "Player2"
        @server.puts( msg )
    end
  end

  def send_position
      data = "#{@player.x}|#{@player.y}|#{@player.angle}"
      @request = Thread.new do
          @server.puts(data)
      end
  end

  def update_position
     @response = Thread.new do
        msg = @server.gets.split('|')
        unless msg[0].length <=0 or msg[1].length <= 0 or msg[2].length <= 0
          @guest.x = msg[0].to_i
          @guest.y = msg[1].to_i
          @guest.angle = msg[2].to_i
        end
    end
  end

  def update
    if button_down? Gosu::KbLeft or button_down? Gosu::GpLeft then
      @player.turn_left
    end
    if button_down? Gosu::KbRight or button_down? Gosu::GpRight then
      @player.turn_right
    end
    if button_down? Gosu::KbUp or button_down? Gosu::GpButton0 then
      @player.accelerate
    end

    @player.move
  end

  def draw
    send_position
    update_position
    @player.draw
    @guest.draw
  end

  def button_down(id)
    if id == Gosu::KbEscape
      close
    end
  end
end

 

window = GameWindow.new
window.show