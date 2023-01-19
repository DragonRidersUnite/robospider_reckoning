module LevelGeneration
  class MazeGenerator
    def initialize(size:)
      @size = size
      @stack = []
    end

    def generate
      @grid = initialize_grid
      @stack = []
      current_cell = @grid[0][0]
      visit_and_remove_wall current_cell

      until @stack.empty?
        current_cell = @stack.last
        neighbors = get_neighbors(current_cell)
        unvisited_neighbors = neighbors.select(&:wall)
        if unvisited_neighbors.empty?
          @stack.pop
        else
          next_cell = unvisited_neighbors.sample
          remove_wall_between(current_cell, next_cell)
          visit_and_remove_wall next_cell
        end
      end
      build_result
    end

    private

    def initialize_grid
      Array.new(@size) { |x|
        Array.new(@size) { |y|
          { x: x, y: y, wall: true }
        }
      }
    end

    def visit_and_remove_wall(cell)
      cell[:wall] = false
      @stack.push(cell)
    end

    def get_neighbors(current_cell)
      [[2, 0], [0, 2], [-2, 0], [0, -2]].map { |offset|
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
