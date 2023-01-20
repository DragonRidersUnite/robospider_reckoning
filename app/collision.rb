module Collision
  class << self
    # Executes the block for each intersections of the collections. If a
    # collection isn't an array, it's put into one so it can properly loop.
    def detect(col1, col2)
      col1 = [col1] unless col1.is_a?(Array)
      col2 = [col2] unless col2.is_a?(Array)

      col1.each do |i|
        col2.each do |j|
          if !i.dead && !j.dead
            if i.intersect_rect?(j)
              yield(i, j)
            end
          end
        end
      end
    end

    def move_out_of_collider(object, collider)
      object_center_x = object[:x] + (object[:w] / 2)
      object_center_y = object[:y] + (object[:h] / 2)
      collider_center_x = collider[:x] + (collider[:w] / 2)
      collider_center_y = collider[:y] + (collider[:h] / 2)

      collider_diagonal_slope = collider[:h] / collider[:w]
      collider_to_object_x = object_center_x - collider_center_x
      collider_to_object_y = object_center_y - collider_center_y
      collider_to_object_slope = collider_to_object_y.abs / [collider_to_object_x.abs, 0.0001].max
      move_direction = if collider_to_object_x >= 0
                         if collider_to_object_y >= 0 # top right
                           collider_to_object_slope > collider_diagonal_slope ? :up : :right
                         else # bottom right
                           collider_to_object_slope > collider_diagonal_slope ? :down : :right
                         end
                       else
                         if collider_to_object_y >= 0 # top left
                           collider_to_object_slope > collider_diagonal_slope ? :up : :left
                         else # bottom left
                           collider_to_object_slope > collider_diagonal_slope ? :down : :left
                         end
                       end

      case move_direction
      when :up
        object[:y] = collider.top
      when :down
        object[:y] = collider.bottom - object[:h]
      when :left
        object[:x] = collider.left - object[:w]
      when :right
        object[:x] = collider.right
      end
    end
  end
end
