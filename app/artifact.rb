module Artifact
  class << self
    SIZE = 32

    def create(args, type)
      pos = spawn_location(args)

      if type == :door
        wall = args
          .state
          .level
          .walls
          .select do |w|
            w.x < pos.x && w.x + w.w > pos.x && w.y > pos.y
          end
          .sort_by { |w| w.y }
          .first
        artifact = {
          x: pos.x - SIZE / 2,
          y: wall.y,
          w: SIZE,
          h: SIZE,
          path: Sprite.for(type)
        }
        artifact if pos
      else
        artifact = {
          x: pos.x - SIZE / 2,
          y: pos.y - SIZE / 2,
          w: SIZE,
          h: SIZE,
          path: Sprite.for(type)
        }
        artifact if pos
      end
    end

    def spawn_location(args)
      level = args.state.level
      grid = level.grid.flatten.reject(&:wall).shuffle
      min_dist = level.grid.size * 0.45
      player = {
        x: args.state.player.x / level.cell_size,
        y: args.state.player.y / level.cell_size
      }

      attempts = 0
      while true
        attempts += 1

        pos = grid.pop

        dist = [(pos.x - player.x).abs, (pos.y - player.y).abs].max
        if dist > min_dist
          pos = {
            x: (pos.x + random(0.4, 0.6)) * level.cell_size,
            y: (pos.y + random(0.4, 0.6)) * level.cell_size
          }
          putz("Took #{attempts} attempts to spawn artifact.") if debug?
          return pos
        end

        if grid.length == 0
          putz("Could not spawn artifact. This is bad.") if debug?
          return nil
        end
      end
    end

    def tick(args, player, familiar, index)
      # no-op for now
    end
  end
end
