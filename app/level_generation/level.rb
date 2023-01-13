class Level
  attr_accessor :grid, :size, :mode, :start_cell
  
  def initialize()
    @mode = "small"
    case @mode
    when "small"
      @size = 30
    when "medium"
      @size = 60
    when "large"
      @size = 90
    end
    
    @grid = Array.new(@size) { Array.new(@size, 1) }
    @cell_size = 128
    create_level()
    @start_cell = select_alive_cell()
  end
  
  def select_alive_cell
    alive_cells = []
    @grid.each do |row|
      row.each do |cell|
        alive_cells << cell if cell.state == 'alive'
      end
    end
    alive_cells.sample
  end
  
  
  def create_level()
    stack = []
    current_cell = [rand(@size), rand(@size)]
    @grid[current_cell[0]][current_cell[1]] = 0
    stack.push(current_cell)
    
    while !stack.empty?
      current_cell = stack.last
      neighbors = [[-1, 0], [1, 0], [0, -1], [0, 1]].map { |d| [current_cell[0] + d[0], current_cell[1] + d[1]] }.select { |c| c[0] >= 0 && c[0] < @size && c[1] >= 0 && c[1] < @size && @grid[c[0]][c[1]] == 1 }
      if !neighbors.empty?
        next_cell = neighbors.sample
        @grid[(current_cell[0] + next_cell[0]) / 2][(current_cell[1] + next_cell[1]) / 2] = 0
        @grid[next_cell[0]][next_cell[1]] = 0
        stack.push(next_cell)
      else
        stack.pop
      end
    end
    
    @grid.each_with_index do |row, x|
      row.each_with_index do |cell, y|
        if cell == 1
          @grid[x][y] = Cell.new(position: Vector.new(x, y), state: 'dead', size: @cell_size, type: determine_cell_type(x, y))
        else
          @grid[x][y] = Cell.new(position: Vector.new(x, y), state: 'alive', size: @cell_size, type: determine_cell_type(x, y))
        end
      end
    end
  end
  
  def determine_cell_type(x, y)
    if x == 0 && y == @size - 1
      'top_left'
    elsif x == 0 && y == 0
      'bottom_left'
    elsif x == @size - 1 && y == @size - 1
      'top_right'
    elsif x == @size - 1 && y == 0
      'bottom_right'
    elsif x == 0
      'left_side'
    elsif x == @size - 1
      'right_side'
    elsif y == @size - 1
      'top_side'
    elsif y == 0
      'bottom_side'
    else
      'center'
    end
  end
  
  def draw(args, camera)
    @grid.each do |row|
      row.each do |cell|
        screen_x = cell.screen.x - camera.position.x
        screen_y = cell.screen.y - camera.position.y
        if (screen_x >= 0 - @cell_size && screen_x < (camera.dimensions.width + @cell_size)) && (screen_y >= 0 - @cell_size && screen_y < camera.dimensions.height + @cell_size)
          if cell.state == 'alive'
            args.outputs.solids << [screen_x, screen_y, @cell_size, @cell_size, 111, 111, 111]
          else
            args.outputs.solids << [screen_x, screen_y, @cell_size, @cell_size, 0, 0, 0]
          end
        end
      end
    end
  end
end