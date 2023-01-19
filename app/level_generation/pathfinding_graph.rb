module LevelGeneration
  module PathfindingGraph
    class << self
      def generate(grid)
        calculate_fiber_result generate_fiber(grid)
      end

      # Returns a fiber that continues to generate a pathfinding graph.
      # The fiber can be resumed with a number of steps to perform.
      # It will either return `nil` if it is not done yet or a hash
      # with the pathfinding graph once it is done.
      def generate_fiber(grid)
        calculate_stepwise_fiber do |fiber_context|
          result = {}
          grid.each_with_index do |column, x|
            column.each_with_index do |cell, y|
              fiber_context.step
              next if cell[:wall]

              [[0, 1], [1, 0], [0, -1], [-1, 0]].each do |(offset_x, offset_y)|
                neighbor_x = x + offset_x
                neighbor_y = y + offset_y
                next if neighbor_x.negative? || neighbor_x >= grid.size
                next if neighbor_y.negative? || neighbor_y >= column.size
                next if grid[neighbor_x][neighbor_y][:wall]

                result[{ x: x, y: y }] ||= []
                result[{ x: x, y: y }] << { x: neighbor_x, y: neighbor_y }
              end
            end
          end
          result
        end
      end
    end
  end
end
