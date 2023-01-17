module LevelGeneration
  module Wall
    class << self
      def covered_by?(wall, other_wall)
        wall == other_wall
      end

      def determine_vertical_walls(grid)
        walls = []

        grid.each_with_index do |column, x|
          current_wall = nil
          column.each_with_index do |cell, y|
            unless current_wall
              current_wall = { x: x, y: y, w: 1, h: 1 } if cell[:wall]
              next
            end

            if cell[:wall]
              current_wall[:h] += 1
              next
            end

            walls << current_wall
            current_wall = nil
          end

          walls << current_wall if current_wall
        end

        walls
      end

      def determine_horizontal_walls(grid)
        walls = []

        grid.transpose.each_with_index do |row, y|
          current_wall = nil
          row.each_with_index do |cell, x|
            unless current_wall
              current_wall = { x: x, y: y, w: 1, h: 1 } if cell[:wall]
              next
            end

            if cell[:wall]
              current_wall[:w] += 1
              next
            end

            walls << current_wall
            current_wall = nil
          end

          walls << current_wall if current_wall
        end

        walls
      end
    end
  end
end