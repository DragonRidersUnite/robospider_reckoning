module Pathfinding
  class << self
  # A-star pathfinding algorithm.
    def find_path(graph, start:, goal:)
      frontier = PriorityQueue.new
      came_from = {start => nil}
      cost_so_far = {start => 0}
      frontier.insert(start, 0)

      until frontier.empty?
        current = frontier.pop
        break if current == goal
        return [] if graph[current].nil?

        graph[current].each do |neighbor|
          # or special cost for this edge
          cost_to_neighbor = 1
          total_cost_to_neighbor = cost_so_far[current] + cost_to_neighbor
          next if cost_so_far.include?(neighbor) && cost_so_far[neighbor] <= total_cost_to_neighbor

          heuristic_value = (neighbor[:x] - goal[:x]).abs + (neighbor[:y] - goal[:y]).abs
          priority = total_cost_to_neighbor + heuristic_value
          frontier.insert(neighbor, priority)
          came_from[neighbor] = current
          cost_so_far[neighbor] = total_cost_to_neighbor
        end
      end

      result = []
      current = goal
      until current.nil?
        result.unshift(current)
        current = came_from[current]
      end

      result
    end
  end

  class PriorityQueue
    def initialize
      @data = [nil]
    end

    def insert(element, priority)
      @data << {element: element, priority: priority}
      heapify_up(@data.size - 1)
    end

    def pop
      result = @data[1]&.element
      last_element = @data.pop
      unless empty?
        @data[1] = last_element
        heapify_down(1)
      end

      result
    end

    def empty?
      @data.size == 1
    end

    def clear
      @data = [nil]
    end

    private

    def heapify_up(index)
      return if index == 1

      parent_index = index.idiv(2)
      return if @data[index].priority >= @data[parent_index].priority

      swap(index, parent_index)
      heapify_up(parent_index)
    end

    def heapify_down(index)
      smallest_child_index = smallest_child_index(index)

      return unless smallest_child_index

      return if @data[index].priority < @data[smallest_child_index].priority

      swap(index, smallest_child_index)
      heapify_down(smallest_child_index)
    end

    def swap(index1, index2)
      @data[index1], @data[index2] = [@data[index2], @data[index1]]
    end

    def smallest_child_index(index)
      left_index = index * 2
      left_value = @data[left_index]
      right_index = (index * 2) + 1
      right_value = @data[right_index]

      return nil unless left_value || right_value
      return left_index unless right_value
      return right_index unless left_value

      left_value.priority < right_value.priority ? left_index : right_index
    end
  end
end
