module LevelGeneration
  class MazeGenerator
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
          { x: x, y: y, wall: (x == 0 || x == @size-1) || (y == 0 || y == @size-1) || rand < 1 }
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
