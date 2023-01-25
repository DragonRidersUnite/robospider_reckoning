module Artifact
  class << self
    def create(args)

      pos = spawn_location(args)

      artifact = {
        x: pos.x - 30,
        y: pos.y - 30,
        w: 60,
        h: 60,
        path: Sprite.for(:artifact),
      }
      artifact if pos
    end
    
    def spawn_location(args)
      level = args.state.level
      grid = level.grid.flatten.reject(&:wall).shuffle
      min_dist = level.grid.size * 0.45
      player = {
        x: args.state.player.x/level.cell_size,
        y: args.state.player.y/level.cell_size
      }

      attempts = 0
      while true
        attempts += 1
        
        pos = grid.pop

        dist = [(pos.x-player.x).abs, (pos.y-player.y).abs].max
        if dist > min_dist
          pos = {
            x: (pos.x + random(0.4, 0.6)) * level.cell_size,
            y: (pos.y + random(0.4, 0.6)) * level.cell_size,
          }
          putz "Took #{attempts} attempts to spawn artifact." if debug?
          return pos
        end
        if grid.length == 0
          putz "Could not spawn artifact. This is bad." if debug?
          return nil
        end
      end
    end

    def tick(args, player, familiar, index)
      #no-op for now
    end
  end
end