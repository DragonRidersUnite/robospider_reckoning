

class Camera
  attr_reader :position, :dimensions
  
  def initialize()
    @position = Vector.new(0, 0)
    @dimensions = Dimensions.new(width: 1280, height: 720)
  end

  def update(args)
    @position.x = args.state.player.sx.idiv(1280) * 1280
    @position.y = args.state.player.sy.idiv(720) * 720
  end

end
