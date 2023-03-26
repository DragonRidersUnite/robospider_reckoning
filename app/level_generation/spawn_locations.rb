# module SpawnLocations
# class << self
# def calculate(level)
# calculate_calculation(level).calculate_in_one_step
# end

# def calculate_calculation(level)
# LongCalculation.define do
# result = {}
# level[:grid].each_with_index do |column, x|
# column.each_with_index do |cell, y|
# next if cell[:wall]

# LongCalculation.finish_step
# position = { x: x, y: y }
# result[position] = coordinates_just_outside_screen(level, position)
# end
# end
# result
# end
# end

# private

# def coordinates_just_outside_screen(level, position)
# cell_size = level[:cell_size]
# screen = {
# x: [(position[:x] * cell_size) + (cell_size / 2) - 640, 0].max,
# y: [(position[:y] * cell_size) + (cell_size / 2) - 360, 0].max,
# w: 1280,
# h: 720
# }

# graph = level[:pathfinding_graph]
# result = []
# visited = { position => true }
# frontier = graph[position].dup
# until frontier.empty?
# next_position = frontier.shift
# visited[next_position] = true

# area = { x: next_position[:x] * cell_size, y: next_position[:y] * cell_size, w: cell_size, h: cell_size }
# if area.intersect_rect? screen
# graph[next_position].each do |neighbor|
# next if visited[neighbor]

# frontier << neighbor
# end
# else
# result << next_position
# end
# end
# result
# end
# end
# end
