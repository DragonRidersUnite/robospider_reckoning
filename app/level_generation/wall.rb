module LevelGeneration
  module Wall
    class << self
      def determine_walls(grid)
        determine_walls_calculation(grid).calculate_in_one_step
      end

      def determine_walls_calculation(grid)
        LongCalculation.define do
          putz "Raw: #{grid.flatten.length}" if debug?
          all_walls = determine_vertical_walls(grid)
          putz "After vertical trimming: #{all_walls.length}" if debug?
          remove_redundant_walls(all_walls)
        end
      end

      def remove_redundant_walls(walls)
        horizontal_walls = {}
        largest = 0
        walls.each do |wall|
          horizontal_walls[wall[:x]] ||= []
          horizontal_walls[wall[:x]] << wall
          largest = [largest, wall[:x]].max
        end
        
        i = 0
        while largest > i
          prev_column = horizontal_walls[i] || []
          new_column = horizontal_walls[i+1] || []
        
          k1 = 0
          k2 = 0

          while prev_column.length > k1 && new_column.length > k2
            LongCalculation.finish_step
            prev_wall = prev_column[k1]
            new_wall = new_column[k2]
            case prev_wall[:y] <=> new_wall[:y]
            when -1
              k1 += 1
            when 1
              k2 += 1
            when 0
              case new_wall[:h] <=> prev_wall[:h]
              when -1
                k1 += 1
              when 1
                k2 += 1
              when 0
                new_wall[:x] -= prev_wall[:w]
                new_wall[:w] += prev_wall[:w]
                prev_column.delete_at(k1)
              end
            end
          end
          i += 1
        end
        result = []
        horizontal_walls.each do |column|
          result.concat(column[1])
        end

        putz "After final trimming: #{result.length}" if debug?

        return result
      end

      def determine_vertical_walls(grid)
        walls = []

        grid.each_with_index do |column, x|
          current_wall = nil
          current_column = []
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

        return walls
      end

    end
  end
end
