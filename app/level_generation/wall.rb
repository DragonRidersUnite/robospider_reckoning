module LevelGeneration
  module Wall
    class << self
      def determine_walls(grid)
        all_walls = determine_vertical_walls(grid) + determine_horizontal_walls(grid)
        remove_redundant_walls(all_walls)
      end

      def remove_redundant_walls(walls)
        remaining_walls = walls.dup
        # Start with the smallest walls and see if they are redundant and work our way up
        walls = walls.sort_by { |wall| wall[:w] * wall[:h] }
        walls.each do |wall|
          other_walls = remaining_walls.reject { |other_wall| other_wall == wall }
          next unless covered_by_walls?(wall, other_walls)

          remaining_walls.delete(wall)
        end
        remaining_walls
      end

      def covered_by_walls?(wall, other_walls)
        remaining_coordinates = coordinates(wall)
        other_walls.each do |other_wall|
          remaining_coordinates -= coordinates(other_wall)
          return true if remaining_coordinates.empty?
        end
        false
      end

      def covered_by_wall?(wall, other_wall)
        return true if wall == other_wall

        (coordinates(wall) - coordinates(other_wall)).empty?
      end

      def coordinates(wall)
        (wall.left...wall.right).map { |x|
          (wall.bottom...wall.top).map { |y|
            { x: x, y: y }
          }
        }.flatten
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
