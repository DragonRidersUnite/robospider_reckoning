module LevelGeneration
  class MazeGenerator
    def self.open_walls(count, grid:, pathfinding_graph:)
      open_walls_calculation(count, grid: grid, pathfinding_graph: pathfinding_graph).calculate_in_one_step
    end

    def self.open_walls_calculation(count, grid:, pathfinding_graph:)
      LongCalculation.define do
        count.times do
          wall_cells = grid.flatten.select(&:wall)
          walls_separating_opposite_corridors = wall_cells.select { |cell|
            LongCalculation.finish_step
            corridor_neighbors = Level::Grid.get_four_neighbors(grid, cell).reject(&:wall)
            next false unless corridor_neighbors.count == 2

            # Only allow walls that separate two corridors that are on opposite sides
            corridor_neighbors[0][:x] == corridor_neighbors[1][:x] ||
              corridor_neighbors[0][:y] == corridor_neighbors[1][:y]
          }
          # TODO: Maybe measure path length between the two corridors and only remove
          #       walls that separate corridors that are separated more than a certain
          #       threshold to create meaningful shortcuts
          removed_wall = walls_separating_opposite_corridors.sample
          removed_wall[:wall] = false
          LevelGeneration::PathfindingGraph.remove_wall(pathfinding_graph, removed_wall.slice(:x, :y))
        end
      end
    end

    def initialize(size:)
      @size = size
      # Make sure the maze is always odd-sized so that it is surrounded by walls
      @size += 1 if @size.even?
    end

    def generate
      generate_calculation.calculate_in_one_step
    end

    def generate_calculation
      LongCalculation.define do
        @grid = initialize_grid
        grow_random_corridors
        build_result
      end
    end

    private

    def grow_random_corridors
      stack = []
      # Start one cell away from the edge to have the maze surrounded by walls
      first_cell = @grid[1][1]
      first_cell[:wall] = false
      stack.push(first_cell)

      until stack.empty?
        LongCalculation.finish_step
        current_cell = stack.last
        neighbors = Level::Grid.get_four_neighbors(@grid, current_cell, distance: 2)
        unvisited_neighbors = neighbors.select(&:wall)
        if unvisited_neighbors.empty?
          stack.pop
        else
          next_cell = unvisited_neighbors.sample
          remove_wall_between(current_cell, next_cell)
          next_cell[:wall] = false
          stack.push(next_cell)
        end
      end
    end

    def initialize_grid
      Array.new(@size) { |x|
        Array.new(@size) { |y|
          { x: x, y: y, wall: true }
        }
      }
    end

    def remove_wall_between(current_cell, next_cell)
      x = (current_cell[:x] + next_cell[:x]).idiv 2
      y = (current_cell[:y] + next_cell[:y]).idiv 2
      @grid[x][y][:wall] = false
    end

    def build_result
      @grid.map do |column|
        column.map do |cell|
          cell.slice(:x, :y, :wall)
        end
      end
    end
  end
end
