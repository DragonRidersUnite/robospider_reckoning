module Level
  CELL_SIZE = 256
  MAZE_SIZE = 30

  class << self
    def generate
      grid = LevelGeneration::MazeGenerator.new(size: MAZE_SIZE).generate
      start_cell = grid.flatten.reject(&:wall).sample
      {
        cell_size: CELL_SIZE,
        bounds: { x: 0, y: 0, w: MAZE_SIZE * CELL_SIZE, h:  MAZE_SIZE * CELL_SIZE },
        grid: grid,
        start_position: {
          x: (start_cell[:x] * CELL_SIZE) + (CELL_SIZE / 2) - (Player::W / 2),
          y: (start_cell[:y] * CELL_SIZE) + (CELL_SIZE / 2) - (Player::H / 2)
        }
      }
    end

    def draw(args, level, camera:)
      cell_size = level[:cell_size]
      level[:grid].each do |row|
        row.each do |cell|
          next unless cell[:wall]

          rendered_cell = {
            x: (cell[:x] * cell_size),
            y: (cell[:y] * cell_size),
            w: cell_size,
            h: cell_size
          }
          next unless rendered_cell.intersect_rect? camera

          args.outputs.sprites << rendered_cell.sprite!(
            x: rendered_cell.x - camera.x,
            y: rendered_cell.y - camera.y,
            path: :pixel,
            r: 111, g: 111, b: 111
          )
        end
      end
    end
  end
end
