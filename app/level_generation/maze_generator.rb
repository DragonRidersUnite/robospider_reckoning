module LevelGeneration
  class MazeGenerator
    def initialize(size:)
      @size = size
      # Make sure the maze is always odd-sized so that it is surrounded by walls
      @size += 1 if @size.even?
    end

    def generate
      @grid = initialize_grid
      grow_random_corridors
      build_result
    end

    private

    def grow_random_corridors
      stack = []
      # Start one cell away from the edge to have the maze surrounded by walls
      first_cell = @grid[1][1]
      first_cell[:wall] = false
      stack.push(first_cell)

      until stack.empty?
        current_cell = stack.last
        neighbors = get_four_neighbors(current_cell, distance: 2)
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

    def get_four_neighbors(current_cell, distance: 1)
      [[distance, 0], [0, distance], [-distance, 0], [0, -distance]].map { |offset|
        x = current_cell[:x] + offset[0]
        y = current_cell[:y] + offset[1]
        @grid[x][y] if x.between?(0, @size - 1) && y.between?(0, @size - 1)
      }.compact
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
