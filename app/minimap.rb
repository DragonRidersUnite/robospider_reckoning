module Minimap
  FACTOR = 32

  class << self
    def draw(args, level:, player:, artifact:, enemies:)
      w = level.bounds.w / FACTOR
      h = level.bounds.h / FACTOR
      minimap = args.outputs[:minimap]
      minimap.width = w
      minimap.height = h
      minimap.primitives << { x: 0, y: 0, w: w, h: h, path: :pixel }.sprite!(BLACK)

      minimap.primitives << level[:walls].map do |wall|
        {
          x: wall.x / FACTOR,
          y: wall.y / FACTOR,
          w: wall.w / FACTOR,
          h: wall.h / FACTOR,
          path: :pixel
        }.sprite!(WHITE)
      end

      minimap.primitives << draw_helper(player, 3, MINI_GREEN)
      minimap.primitives << draw_helper(artifact, 5, MINI_BLUE)

      enemies.each do |enemy|
        minimap.primitives << draw_helper(enemy, 3, MINI_RED)
      end if debug?

      args.outputs.primitives << { x: 1280 - w - 10, y: 10, w: w, h: h, path: :minimap }.sprite!
    end

    def draw_helper(entity, size, color)
      {
        x: (entity.x / FACTOR) - (size / 2).floor,
        y: (entity.y / FACTOR) - (size / 2).floor,
        w: size,
        h: size,
        path: :pixel,
      }.sprite!(color)
    end
  end
end
