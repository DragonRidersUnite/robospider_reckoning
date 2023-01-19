# To run the tests: ./run_tests
#
# Available assertions:
# assert.true!
# assert.false!
# assert.equal!
#
# View more details: https://github.com/DragonRidersUnite/dragon_test

return unless debug?

def run_tests
  $gtk.tests&.passed.clear
  $gtk.tests&.inconclusive.clear
  $gtk.tests&.failed.clear
  puts "running tests"
  $gtk.reset 100
  $gtk.log_level = :on
  $gtk.tests.start

  if $gtk.tests.failed.any?
    puts "🙀 tests failed!"
    failures = $gtk.tests.failed.uniq.map do |failure|
      "🔴 ##{failure[:m]} - #{failure[:e]}"
    end

    if $gtk.cli_arguments.keys.include?(:"exit-on-fail")
      $gtk.write_file("test-failures.txt", failures.join("\n"))
      exit(1)
    end
  else
    puts "🪩 tests passed!"
  end
end

# an optional BDD-like method to use to group and document tests
def it(message)
  yield
end

def test(method)
  test_name = "test_#{method}"
  define_method(test_name) do |args, assert|
    # define custom assertions here!
    # assert.define_singleton_method(:rect!) do |obj|
    #   assert.true!(obj.x && obj.y && obj.w && obj.h, "doesn't have needed properties")
    # end
    assert.define_singleton_method(:exception!) do |lamb, error_class, message|
      begin
        lamb.call(args)
      rescue StandardError => e
        assert.equal!(e.class, error_class)
        assert.equal!(e.message, message)
      end
    end

    yield(args, assert)
  end
end

test :menu_text_for_setting_val do |args, assert|
  assert.equal!(Menu.text_for_setting_val(true), "ON")
  assert.equal!(Menu.text_for_setting_val(false), "OFF")
  assert.equal!(Menu.text_for_setting_val("other"), "other")
end

test :out_of_bounds do |args, assert|
  grid = {
    x: 0,
    y: 0,
    w: 1280,
    h: 720,
  }
  assert.true!(out_of_bounds?(grid, { x: -30, y: 30, w: 24, h: 24 }))
  assert.true!(out_of_bounds?(grid, { x: 30, y: -50, w: 24, h: 24 }))
  assert.false!(out_of_bounds?(grid, { x: 30, y: 30, w: 24, h: 24 }))
end

test :angle_for_dir do |args, assert|
  assert.equal!(angle_for_dir(DIR_RIGHT), 0)
  assert.equal!(angle_for_dir(DIR_LEFT), 180)
  assert.equal!(angle_for_dir(DIR_UP), 90)
  assert.equal!(angle_for_dir(DIR_DOWN), 270)
end

test :vel_from_angle do |args, assert|
  it "calculates core four angles properly" do
    assert.equal!(vel_from_angle(0, 5), [5.0, 0.0])
    assert.equal!(vel_from_angle(90, 5).map { |v| v.round(2) }, [0.0, 5.0])
    assert.equal!(vel_from_angle(180, 5).map { |v| v.round(2) }, [-5.0, 0.0])
    assert.equal!(vel_from_angle(270, 5).map { |v| v.round(2) }, [0.0, -5.0])
  end

  it "calculates other values as expected" do
    assert.equal!(vel_from_angle(12, 5).map { |v| v.round(2) }, [4.89, 1.04])
  end
end

test :open_entity_to_hash do |args, assert|
  it "strips OpenEntity keys" do
    args.state.foo.bar = true
    args.state.foo.biz = false
    assert.equal!(open_entity_to_hash(args.state.foo), { bar: true, biz: false })
  end
end

test :game_setting_settings_for_save do |args, assert|
  it "joins hash keys and values" do
    assert.equal!(GameSetting.settings_for_save({ fullscreen: true, sfx: false}), "fullscreen:true,sfx:false")
  end
end

test :text do |args, assert|
  it "returns the value for the passed in key" do
    assert.equal!(text(:game_over), "Game Over")
  end

  it "raises when the key isn't present" do
    assert.exception!(-> (_) { text(:not_present) }, KeyError, "Key not found: :not_present")
  end
end

test :opposite_angle do |args, assert|
  it "returns the diametrically opposed angle" do
    assert.equal!(opposite_angle(0), 180)
    assert.equal!(opposite_angle(180), 0)
    assert.equal!(opposite_angle(360), 180)
    assert.equal!(opposite_angle(90), 270)
    assert.equal!(opposite_angle(270), 90)
  end
end

test :add_to_angle do |args, assert|
  it "returns the new angle on the circle" do
    assert.equal!(add_to_angle(0, 30), 30)
    assert.equal!(add_to_angle(0, -30), 330)
    assert.equal!(add_to_angle(180, -30), 150)
    assert.equal!(add_to_angle(320, 60), 20)
    assert.equal!(add_to_angle(320, -60), 260)
  end
end

test :percent_chance? do |args, assert|
  it "returns false if the percent is 0" do
    assert.false!(percent_chance?(0))
  end

  it "returns true if the percent is 100" do
    assert.true!(percent_chance?(100))
  end
end

def build_grid_from_map(map)
  converted_map = map.split("\n").map { |row|
    row[1..-2].chars.map { |char|
      { wall: char == "X" }
    }
  }
  converted_map.reverse   # reverse the rows since y goes upwards
               .transpose # grids are stored as columns since you access them as grid[x][y]
end

test :level_generation_wall_determine_vertical_walls do |_args, assert|
  grid = build_grid_from_map <<~MAP
    |X XX|
    |XX  |
    |XX  |
  MAP


  walls = LevelGeneration::Wall.determine_vertical_walls grid

  assert.equal! walls, [
    { x: 0, y: 0, w: 1, h: 3 },
    { x: 1, y: 0, w: 1, h: 2 },
    { x: 2, y: 2, w: 1, h: 1 },
    { x: 3, y: 2, w: 1, h: 1 }
  ]
end

test :level_generation_wall_determine_horizontal_walls do |_args, assert|
  grid = build_grid_from_map <<~MAP
    |X XX|
    |XX  |
    |XX  |
  MAP

  walls = LevelGeneration::Wall.determine_horizontal_walls grid

  assert.equal! walls, [
    { x: 0, y: 0, w: 2, h: 1 },
    { x: 0, y: 1, w: 2, h: 1 },
    { x: 0, y: 2, w: 1, h: 1 },
    { x: 2, y: 2, w: 2, h: 1 }
  ]
end

test :level_generation_wall_covered_by_wall do |_args, assert|
  [
    [{ x: 0, y: 0, w: 1, h: 1 }, { x: 0, y: 0, w: 1, h: 1 }, true, true],
    [{ x: 0, y: 0, w: 1, h: 1 }, { x: 0, y: 0, w: 2, h: 1 }, true, false],
    [{ x: 0, y: 0, w: 1, h: 1 }, { x: 0, y: 0, w: 1, h: 2 }, true, false],
    [{ x: 1, y: 0, w: 1, h: 1 }, { x: 0, y: 0, w: 2, h: 1 }, true, false],
    [{ x: 0, y: 1, w: 1, h: 1 }, { x: 0, y: 0, w: 1, h: 2 }, true, false],
    [{ x: 0, y: 0, w: 1, h: 3 }, { x: 1, y: 0, w: 1, h: 1 }, false, false]
  ].each do |wall, other_wall, expected, opposite_case_expected|
    assert.equal! LevelGeneration::Wall.covered_by_wall?(wall, other_wall),
                  expected,
                  "Expected #{wall} #{expected ? '' : 'not '}to be covered by #{other_wall}"

    assert.equal! LevelGeneration::Wall.covered_by_wall?(other_wall, wall),
                  opposite_case_expected,
                  "Expected #{other_wall} #{opposite_case_expected ? '' : 'not '}to be covered by #{wall}"
  end
end

test :level_generation_wall_coordinates do |_args, assert|
  assert.equal! LevelGeneration::Wall.coordinates({ x: 0, y: 0, w: 2, h: 1 }), [
    { x: 0, y: 0 },
    { x: 1, y: 0 }
  ]
end

test :level_generation_wall_covered_by_walls do |_args, assert|
  walls = [
    { x: 0, y: 0, w: 1, h: 2 },
    { x: 1, y: 0, w: 1, h: 3 }
  ]

  assert.true! LevelGeneration::Wall.covered_by_walls?({ x: 0, y: 0, w: 2, h: 1 }, walls)
  assert.false! LevelGeneration::Wall.covered_by_walls?({ x: 0, y: 0, w: 3, h: 1 }, walls)
end

test :level_generation_wall_determine_walls do |_args, assert|
  grid = build_grid_from_map <<~MAP
    |X XX|
    |X   |
    |XXX |
  MAP

  walls = LevelGeneration::Wall.determine_walls grid

  assert.equal! walls, [
    # vertical walls
    { x: 0, y: 0, w: 1, h: 3 },
    # horizontal walls
    { x: 0, y: 0, w: 3, h: 1 },
    { x: 2, y: 2, w: 2, h: 1 }
  ]
end

test :level_generation_pathfinding_graph_generate do |_args, assert|
  grid = build_grid_from_map <<~MAP
    |XXXXX|
    |XX XX|
    |X   X|
    |XX XX|
    |XXXXX|
  MAP

  graph = LevelGeneration::PathfindingGraph.generate grid

  assert.equal! graph, {
    { x: 2, y: 1 } => [{ x: 2, y: 2 }],
    { x: 2, y: 2 } => [{ x: 2, y: 3 }, { x: 3, y: 2 }, { x: 2, y: 1 }, { x: 1, y: 2 }],
    { x: 2, y: 3 } => [{ x: 2, y: 2 }],
    { x: 3, y: 2 } => [{ x: 2, y: 2 }],
    { x: 1, y: 2 } => [{ x: 2, y: 2 }]
  }
end

test :collision_move_out_of_collider do |_args, assert|
  collider = { x: 100, y: 100, w: 100, h: 100 }

  [
    { before: { x: 195, y: 150, w: 10, h: 10 }, after: { x: 200, y: 150, w: 10, h: 10 } }, # from the right
    { before: { x: 95, y: 150, w: 10, h: 10 }, after: { x: 90, y: 150, w: 10, h: 10 } },  # from the left
    { before: { x: 150, y: 195, w: 10, h: 10 }, after: { x: 150, y: 200, w: 10, h: 10 } }, # from the top
    { before: { x: 150, y: 95, w: 10, h: 10 }, after: { x: 150, y: 90, w: 10, h: 10 } }   # from the bottom
  ].each do |test_case|
    object = test_case[:before].dup

    Collision.move_out_of_collider object, collider

    assert.equal! object,
                  test_case[:after],
                  "Expected #{test_case[:before]} to be moved out of #{collider} to #{test_case[:after]}\nbut got #{object}"
  end
end

test :long_calculation_basic_behaviour do |_args, assert|
  progress = []
  calculation = LongCalculation.define do
    10.times do |i|
      progress << i
      LongCalculation.finish_step
    end
    :finished
  end

  result = calculation.resume 5

  assert.equal! progress, [0, 1, 2, 3, 4]
  assert.nil! result

  result = calculation.resume 3

  assert.equal! progress, [0, 1, 2, 3, 4, 5, 6, 7]
  assert.nil! result

  result = calculation.resume 3

  assert.equal! progress, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
  assert.equal! result, :finished
end

test :calculate_as_stepwise_fiber_calculate_in_one_step do |_args, assert|
  progress = []
  fiber = calculate_as_stepwise_fiber do
    10.times do |i|
      progress << i
      $fiber_context.step
    end
    :finished
  end

  result = fiber.calculate_in_one_step

  assert.equal! progress, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
  assert.equal! result, :finished
  assert.nil! $fiber_context
end

test :calculate_as_stepwise_fiber_nested do |_args, assert|
  progress = []
  fiber = calculate_as_stepwise_fiber do
    progress << 1
    $fiber_context.step
    sub_fiber = calculate_as_stepwise_fiber do
      progress << 2
      $fiber_context.step
      progress << 3
      $fiber_context.step
      :sub_finished
    end
    sub_fiber.calculate_in_one_step
  end

  result = fiber.resume 2

  assert.equal! progress, [1, 2]
  assert.nil! result
  assert.nil! $fiber_context

  result = fiber.resume 2

  assert.equal! progress, [1, 2, 3]
  assert.equal! result, :sub_finished
  assert.nil! $fiber_context
end

test :calculate_as_stepwise_fiber_run_for_ms do |_args, assert|
  fiber = calculate_as_stepwise_fiber do
    loop do
      $fiber_context.step
    end
  end

  start_time = Time.now.to_f
  result = fiber.run_for_ms(5)
  end_time = Time.now.to_f

  run_time = (end_time - start_time) * 1000
  assert.true! run_time.between?(5, 10), "Expected fiber to run for rougly 5ms but it ran for #{run_time}ms"
  assert.nil! result
  assert.nil! $fiber_context
end

run_tests
