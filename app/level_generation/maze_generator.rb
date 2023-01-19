module LevelGeneration
  class MazeGenerator
    def initialize(size:)
      @size = size
      # Make sure the maze is always odd-sized so that it is surrounded by walls
      @size += 1 if @size.even?
    end

    def generate
      fiber = generate_fiber
      result = fiber.resume(1000) while result.nil?
      result
    end

    def generate_fiber
      Fiber.new do |steps|
        @steps = steps

        @grid = initialize_grid
        grow_random_corridors
        add_some_more_connections
        Fiber.yield build_result
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
        count_fiber_step
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
      [[distance, 0], [0, distance], [-distance, 0], [0, -distance]].map { |(offset_x, offset_y)|
        x = current_cell[:x] + offset_x
        y = current_cell[:y] + offset_y
        @grid[x][y] if x.between?(0, @size - 1) && y.between?(0, @size - 1)
      }.compact
    end

    def remove_wall_between(current_cell, next_cell)
      x = (current_cell[:x] + next_cell[:x]).idiv 2
      y = (current_cell[:y] + next_cell[:y]).idiv 2
      @grid[x][y][:wall] = false
    end

    def add_some_more_connections
      # TODO: Probably need to make this configurable or derive it from the maze size
      10.times do
        wall_cells = @grid.flatten.select(&:wall)
        walls_separating_opposite_corridors = wall_cells.select { |cell|
          count_fiber_step
          corridor_neighbors = get_four_neighbors(cell).reject(&:wall)
          next false unless corridor_neighbors.count == 2

          # Only allow walls that separate two corridors that are on opposite sides
          corridor_neighbors[0][:x] == corridor_neighbors[1][:x] ||
            corridor_neighbors[0][:y] == corridor_neighbors[1][:y]
        }
        # TODO: Maybe measure path length between the two corridors and only remove
        #       walls that separate corridors that are separated more than a certain
        #       threshold to create meaningful shortcuts
        walls_separating_opposite_corridors.sample[:wall] = false
      end
    end

    def build_result
      @grid.map do |column|
        column.map do |cell|
          cell.slice(:x, :y, :wall)
        end
      end
    end

    def count_fiber_step
      @steps -= 1
      @steps = Fiber.yield if @steps.zero?
    end
  end
end
