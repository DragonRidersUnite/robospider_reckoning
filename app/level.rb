module Level
  CELL_SIZE = 256
  MAZE_SIZE = 30

  class << self
    def generate
      generate_calculation.calculate_in_one_step
    end

    def generate_calculation
      LongCalculation.define do
        grid = LevelGeneration::MazeGenerator.new(size: MAZE_SIZE).generate
        start_cell = grid.flatten.reject(&:wall).sample
        walls = LevelGeneration::Wall.determine_walls(grid)
        {
          cell_size: CELL_SIZE,
          bounds: { x: 0, y: 0, w: grid.size * CELL_SIZE, h: grid.size * CELL_SIZE },
          grid: grid,
          walls: walls.map { |wall|
            {
              x: wall[:x] * CELL_SIZE,
              y: wall[:y] * CELL_SIZE,
              w: wall[:w] * CELL_SIZE,
              h: wall[:h] * CELL_SIZE
            }
          },
          start_position: {
            x: (start_cell[:x] * CELL_SIZE) + (CELL_SIZE / 2) - (Player::W / 2),
            y: (start_cell[:y] * CELL_SIZE) + (CELL_SIZE / 2) - (Player::H / 2)
          },
          pathfinding_graph: LevelGeneration::PathfindingGraph.generate(grid)
        }
      end
    end

    def draw(args, level, camera:)
      level[:walls].each do |wall|
        next unless wall.intersect_rect? camera

        args.outputs.sprites << wall.to_sprite(
          x: wall.x - camera.x,
          y: wall.y - camera.y,
          path: :pixel,
          r: 111, g: 111, b: 111
        )
      end
    end
  end
end
