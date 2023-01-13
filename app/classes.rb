class Vector
  attr_reader :x, :y, :z
  attr_writer :x, :y, :z
  
  def initialize(x, y)
    @x = x
    @y = y
    @z = 0
  end
end

class Dimensions
  attr_reader :width, :height
  
  def initialize(width:, height:)
    @width = width
    @height = height
  end
  
end