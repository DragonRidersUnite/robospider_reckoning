module Minimap
  FACTOR = 32
  class << self
    def draw(args, level:, player:, enemies:)
      w = level.bounds.w / FACTOR
      h = level.bounds.h / FACTOR
      minimap = args.outputs[:minimap]
      minimap.width = w
      minimap.height = h
      minimap.primitives << { x: 0, y: 0, w: w, h: h, path: :pixel }.sprite!(BLACK)
      level[:walls].each do |wall|
        minimap.primitives << {
          x: wall.x / FACTOR, y: wall.y / FACTOR, w: wall.w / FACTOR, h: wall.h / FACTOR,
          path: :pixel
        }.sprite!(WHITE)
      end
      minimap.primitives << {
        x: (player.x / FACTOR) - 1, y: (player.y / FACTOR) - 1, w: 3, h: 3, path: :pixel,
        r: 0, g: 255, b: 0
      }.sprite!
      enemies.each do |enemy|
        minimap.primitives << {
          x: (enemy.x / FACTOR) - 1, y: (enemy.y / FACTOR) - 1, w: 3, h: 3, path: :pixel,
          r: 255, g: 0, b: 0
        }.sprite!
      end

      args.outputs.primitives << { x: 10, y: 10, w: w, h: h, path: :minimap, a: 192 }.sprite!
    end
  end
end
