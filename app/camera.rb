

class Camera
  attr_reader :position, :dimensions

  def initialize()
    @position = { x: 0, y: 0 }
    @dimensions = { w: 1280, h: 720 }
  end

  def update(args)
    @position.x = args.state.player.sx.idiv(1280) * 1280
    @position.y = args.state.player.sy.idiv(720) * 720
  end

end
