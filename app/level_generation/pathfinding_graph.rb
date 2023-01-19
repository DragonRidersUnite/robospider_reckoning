module LevelGeneration
  module PathfindingGraph
    class << self
      def generate(grid)
        result = {}
        grid.each_with_index do |column, x|
          column.each_with_index do |cell, y|
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
