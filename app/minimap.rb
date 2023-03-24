module Minimap
  FACTOR_LG = 12
  FACTOR_SM = 32

  class << self
    def draw(args, x:, y:, factor:, level:, player:, artifact:, enemies:)
      w = level.bounds.w / factor
      h = level.bounds.h / factor

      minimap = args.outputs[:minimap]
      minimap.width = w
      minimap.height = h

      minimap.primitives << {x: 0, y: 0, w: w, h: h, path: :pixel}.sprite!(BLACK)
      minimap.primitives <<
        level[:walls].map do |wall|
          {
            x: wall.x / factor,
            y: wall.y / factor,
            w: wall.w / factor,
            h: wall.h / factor,
            path: :pixel
          }.sprite!(WHITE)
        end

      minimap.primitives << draw_helper(player, 3, MINI_GREEN, factor)
      minimap.primitives << draw_helper(artifact, 5, MINI_BLUE, factor)

      if debug?
        enemies.each do |enemy|
          minimap.primitives << draw_helper(enemy, 3, MINI_RED, factor)
        end
      end

      args.outputs.primitives << {x: x, y: y, w: w, h: h, path: :minimap}.sprite!
    end

    def draw_helper(entity, size, color, factor)
      {
        x: (entity.x / factor) - (size / 2).floor,
        y: (entity.y / factor) - (size / 2).floor,
        w: size,
        h: size,
        path: :pixel
      }.sprite!(color)
    end

    def size(factor:, level:)
      {
        w: level.bounds.w / factor,
        h: level.bounds.h / factor
      }
    end
  end
end
