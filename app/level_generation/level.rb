class Level
  attr_accessor :grid, :size, :mode, :start_cell

  def initialize(mode:)
    @mode = mode
    case @mode
    when "small"
      @size = 30
    when "medium"
      @size = 60
    when "large"
      @size = 90
    end
    @cell_size = 128
    create_grid_cells()
    create_level()
    @start_cell = select_alive_cell()
  end

  def create_grid_cells()
    @grid = Array.new(@size) { |x|
      Array.new(@size) { |y|
        Cell.new(position: { x: x, y: y }, alive: false, visited: false)
      }
    }
  end

  def select_alive_cell()
    alive_cells = []
    @grid.each do |row|
      row.each do |cell|
        alive_cells << cell if cell.alive
      end
    end
    alive_cells.sample.position
  end


  def create_level
    current_cell = @grid[0][0]
    current_cell.alive = true
    current_cell.visited = true
    stack = []
    stack.push(current_cell)

    while !stack.empty?
      current_cell = stack.last
      neighbors = []
      get_neighbors(neighbors, current_cell)
      unvisited_neighbors = neighbors.select { |neighbor| neighbor.visited == false }
      if !unvisited_neighbors.empty?
        next_cell = unvisited_neighbors.sample
        mark_cell_in_between_alive(current_cell, next_cell)
        next_cell.alive = true
        next_cell.visited = true
        stack.push(next_cell)
      else
        stack.pop
      end
    end
  end

  def get_neighbors(neighbors, current_cell)
    @grid.each do |row|
      row.each do |cell|
        x_diff = (cell.position.x - current_cell.position.x).abs
        y_diff = (cell.position.y - current_cell.position.y).abs
        if x_diff == 2 && y_diff == 0
          neighbors << cell
        elsif x_diff == 0 && y_diff == 2
          neighbors << cell
        end
      end
    end
  end

  def mark_cell_in_between_alive(current_cell, next_cell)
    x_diff = (current_cell.position.x - next_cell.position.x).abs
    y_diff = (current_cell.position.y - next_cell.position.y).abs

    if x_diff == 2
      x = (current_cell.position.x + next_cell.position.x) / 2
      y = current_cell.position.y
      @grid[x][y].alive = true
    elsif y_diff == 2
      x = current_cell.position.x
      y = (current_cell.position.y + next_cell.position.y) / 2
      @grid[x][y].alive = true
    end
  end


  def draw(args, camera)
    @grid.each do |row|
      row.each do |cell|
        screen_x = cell.screen.x - camera.x
        screen_y = cell.screen.y - camera.y
        if (screen_x >= 0 - @cell_size && screen_x < (camera.w + @cell_size)) && (screen_y >= 0 - @cell_size && screen_y < camera.h + @cell_size)
          if cell.alive
            args.outputs.solids << [screen_x, screen_y, @cell_size, @cell_size, 111, 111, 111]
          else
            args.outputs.solids << [screen_x, screen_y, @cell_size, @cell_size, 0, 0, 0]
          end
        end
      end
    end
  end
end
