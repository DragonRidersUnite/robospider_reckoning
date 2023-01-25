# EXQUISITE CORPS
# ~a collaborative jam of chaos~

# add your name to this array!
CREDITS = [
  "Brett Chalupa",
  "Jae Donley",
  "Kevin Fischer",
  "Jonas Grandt",
].shuffle

require "app/input.rb"
require "app/sprite.rb"

require "app/camera.rb"
require "app/constants.rb"
require "app/collision.rb"
require "app/enemy.rb"
require "app/exp_chip.rb"
require "app/familiar.rb"
require "app/artifact.rb"
require "app/level.rb"
require "app/level_generation/maze_generator.rb"
require "app/level_generation/pathfinding_graph.rb"
require "app/level_generation/spawn_locations.rb"
require "app/level_generation/wall.rb"
require "app/long_calculation.rb"
require "app/menu.rb"
require "app/minimap.rb"
require "app/pathfinding.rb"
require "app/player.rb"
require "app/scene.rb"
require "app/game_setting.rb"
require "app/sound.rb"
require "app/text.rb"
require "app/timer.rb"

require "app/scenes/game_over.rb"
require "app/scenes/gameplay.rb"
require "app/scenes/level_generation.rb"
require "app/scenes/main_menu.rb"
require "app/scenes/paused.rb"
require "app/scenes/settings.rb"

# NOTE: add all requires above this

require "app/tick.rb"
