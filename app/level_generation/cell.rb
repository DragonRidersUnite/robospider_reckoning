class Cell
  attr_accessor :alive, :screen, :position, :visited, :size

  def initialize(position:, alive:, visited:)
    @position = position
    @visited = visited
    @alive = alive
    @size = 128
    @screen = { x: @position.x * @size, y: @position.y * @size }
  end

  # def to_s
  #   {
  #     position: @position,
  #     visited: @visited,
  #     alive: @alive,
  #     size: 128,
  #     screen: @screen
  #   }
  # end
end