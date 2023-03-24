module Level
  CELL_SIZE = 114
  MAZE_SIZE = 20

  NAMES = [
    "Storage",
    "Computer Lab",
    "Analysis",
    "Archive",
    "Fabrication",
    "Robotics",
    "Genetic Engineering",
    "Containment",
    "Hazardous Waste",
    "Power Plant"
  ]

  MAX_LEVEL = NAMES.length
  BOSS_LEVEL = MAX_LEVEL - 1

  module Grid
    class << self
      def get_four_neighbors(grid, cell, distance: 1)
        grid_w = grid.size
        grid_h = grid.first.size
        [[distance, 0], [0, distance], [-distance, 0], [0, -distance]]
          .map { |(offset_x, offset_y)|
            x = cell[:x] + offset_x
            y = cell[:y] + offset_y
            grid[x][y] if x.between?(0, grid_w - 1) && y.between?(0, grid_h - 1)
          }
          .compact
      end
    end
  end

  class << self
    def generate
      generate_calculation.calculate_in_one_step
    end

    def generate_calculation
      LongCalculation.define do
        grid = LevelGeneration::MazeGenerator.new(size: MAZE_SIZE).generate
        pathfinding_graph = LevelGeneration::PathfindingGraph.generate(grid)
        # TODO: Probably need to make this 10 configurable or derive it from the maze size
        LevelGeneration::MazeGenerator.open_walls(10, grid: grid, pathfinding_graph: pathfinding_graph)

        start_cell = grid.flatten.reject(&:wall).sample
        walls = LevelGeneration::Wall.determine_walls(grid)

        level = {
          cell_size: CELL_SIZE,
          bounds: {x: 0, y: 0, w: grid.size * CELL_SIZE, h: grid.size * CELL_SIZE},
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
          pathfinding_graph: pathfinding_graph
        }

        #level[:spawn_locations] = LevelGeneration::SpawnLocations.calculate(level)
        level
      end
    end

    def draw(args, level, camera)
      level[:walls].each do |wall|
        next unless wall.intersect_rect?(camera)

        args.outputs.sprites << wall.to_sprite(
          x: wall.x - camera.x,
          y: wall.y - camera.y,
          path: :pixel,
          r: 111,
          g: 111,
          b: 111
        )
      end
    end
  end
end
