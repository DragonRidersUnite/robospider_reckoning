module LevelGeneration
  class << self
    def extract_walls(grid)
      Wall.determine_vertical_walls(grid) + Wall.determine_horizontal_walls(grid)
    end
  end
end
