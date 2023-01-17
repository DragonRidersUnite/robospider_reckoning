module LevelGeneration
  class << self
    def extract_walls(grid)
      walls = []

      walls += [
        { x: 0, y: 0, w: 1, h: 3 },
        { x: 1, y: 0, w: 1, h: 2 },
        { x: 2, y: 2, w: 1, h: 1 },
        { x: 3, y: 2, w: 1, h: 1 },
        { x: 0, y: 0, w: 2, h: 1 },
        { x: 0, y: 1, w: 2, h: 1 },
        { x: 0, y: 2, w: 1, h: 1 },
        { x: 2, y: 2, w: 2, h: 1 }
      ]
      walls
    end
  end
end
