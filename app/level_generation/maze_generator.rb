module LevelGeneration
  class MazeGenerator
    def initialize(size:)
      @size = size
    end

    def generate
      @grid = initialize_grid
      current_cell = @grid[0][0]
      current_cell[:wall] = true
      current_cell[:visited] = true
      stack = []
      stack.push(current_cell)

      until stack.empty?
        current_cell = stack.last
        neighbors = get_neighbors(current_cell)
        unvisited_neighbors = neighbors.reject(&:visited)
        if unvisited_neighbors.empty?
          stack.pop
        else
          next_cell = unvisited_neighbors.sample
          mark_cell_in_between_as_wall(current_cell, next_cell)
          next_cell[:wall] = true
          next_cell[:visited] = true
          stack.push(next_cell)
        end
      end
      build_result
    end

    private

    def initialize_grid
      Array.new(@size) { |x|
        Array.new(@size) { |y|
          { x: x, y: y, wall: false, visited: false }
        }
      }
    end

    def get_neighbors(current_cell)
      [[2, 0], [0, 2], [-2, 0], [0, -2]].map { |offset|
        x = current_cell[:x] + offset[0]
        y = current_cell[:y] + offset[1]
        @grid[x][y] if x.between?(0, @size - 1) && y.between?(0, @size - 1)
      }.compact
    end

    def mark_cell_in_between_as_wall(current_cell, next_cell)
      x = (current_cell[:x] + next_cell[:x]).idiv 2
      y = (current_cell[:y] + next_cell[:y]).idiv 2
      @grid[x][y][:wall] = true
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