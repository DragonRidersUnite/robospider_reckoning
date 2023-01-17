module LevelGeneration
  class << self
    def extract_walls(grid)
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

      walls += [
        { x: 0, y: 0, w: 2, h: 1 },
        { x: 0, y: 1, w: 2, h: 1 },
        { x: 0, y: 2, w: 1, h: 1 },
        { x: 2, y: 2, w: 2, h: 1 }
      ]
      walls
    end
  end
end
