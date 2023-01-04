# To run the tests: ./dragonruby mygame --eval mygame/app/tests.rb --no-tick
#
# methods prefixed with `test_` get run automatically and have `args` and
# `assert` passed in.
#
# assert.true!
# assert.false!
# assert.equal!

def test(method)
  test_name = "test_#{method}"
  define_method(test_name) do |args, assert|
    yield(args, assert)
    puts "✅ #{test_name}"
  end
end

test :text_for_setting_val do |args, assert|
  assert.equal!(text_for_setting_val(true), "ON")
  assert.equal!(text_for_setting_val(false), "OFF")
  assert.equal!(text_for_setting_val("other"), "other")
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

puts "running tests"
$gtk.reset 100
$gtk.log_level = :off
$gtk.tests.start
