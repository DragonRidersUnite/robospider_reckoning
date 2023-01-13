class Cell
  attr_accessor :state, :neighbors, :screen, :position, :type, :rule_set
  def initialize(position:, state:, size:, type:)
    @state = state
    @size = size
    @type = type
    @position = position
    @screen = Vector.new(@position.x * @size, @position.y * @size)
  end
end



# this is ancient...
# class Cell
#   attr_accessor :state, :neighbors, :screen, :position, :type, :rule_set
#   def initialize(position:, state:, size:, type:)
#     @state = state
#     @size = size
#     @type = type
#     @position = position
#     @screen = Vector.new(@position.x * @size, @position.y * @size)
#     @neighbors = []
#     @rule_set = 'Conway'
#   end
  
#   def update_state(new_state)
#     @state = new_state
#   end
  
#   def get_neighbors(grid)      
#     @neighbors = case @type
#     when 'top_left'
#       [grid[@position.x + 1][@position.y], grid[@position.x][@position.y - 1]]
#     when 'top_right'
#       [grid[@position.x - 1][@position.y], grid[@position.x][@position.y - 1]]
#     when 'bottom_left'
#       [grid[@position.x + 1][@position.y], grid[@position.x][@position.y + 1]]
#     when 'bottom_right'
#       [grid[@position.x - 1][@position.y], grid[@position.x][@position.y + 1]]
#     when 'left_side'
#       [grid[@position.x + 1][@position.y], grid[@position.x][@position.y + 1], grid[@position.x][@position.y - 1]]
#     when 'right_side'
#       [grid[@position.x - 1][@position.y], grid[@position.x][@position.y + 1], grid[@position.x][@position.y - 1]]
#     when 'top_side'
#       [grid[@position.x + 1][@position.y], grid[@position.x][@position.y - 1]]
#     when 'bottom_side'
#       [grid[@position.x + 1][@position.y], grid[@position.x][@position.y + 1]]
#     when 'center'
#       [grid[@position.x + 1][@position.y], grid[@position.x][@position.y + 1], grid[@position.x][@position.y - 1]]
#     end
#   end
  
  
#   def next_state(grid)
#     alive_neighbors = count_alive_neighbors(grid)
#     case @rule_set
#     when 'Conway'
#       if alive_neighbors < 2 || alive_neighbors > 3
#         return 'dead'
#       elsif alive_neighbors == 3
#         return 'alive'
#       else
#         return @state
#       end
#     when 'HighLife'
#       if alive_neighbors == 3 || alive_neighbors == 6
#         return 'alive'
#       else
#         return 'dead'
#       end
#     end
#   end
  
#   def get_neighbors_of_state(state)
#     neighbors.select { |neighbor| neighbor.state == state }
#   end  
  
#   def count_alive_neighbors(grid)
#     alive_neighbors = 0
#     @neighbors.each do |_, neighbor|
#       x, y = neighbor.x, neighbor.y
#       if x >= 0 && x < grid.size && y >= 0 && y < grid[0].size
#         alive_neighbors += 1 if grid[x][y].state == 'alive'
#       end
#     end
#     alive_neighbors
#   end
  
#   def update(grid)
#     @state = next_state(grid)
#   end
  
#   def tick(grid)
#     @neighbors = get_neighbors
#     update(grid)
#   end
  
#   def to_s
#     "Cell(x: #{@position.x}, y: #{@position.y}, state: #{@state})"
#   end
  
#   def is_alive?
#     @state == 'alive'
#   end
  
#   def on_edge?(grid)
#     x, y = @position.x, @position.y
#     x == 0 || y == 0 || x == grid.size - 1 || y == grid[0].size - 1
#   end
# end
