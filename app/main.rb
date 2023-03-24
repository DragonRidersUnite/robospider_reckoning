# EXQUISITE CORPS
# ~a collaborative jam of chaos~

# add your name to this array!
CREDITS = [
  "Brett Chalupa",
  "Jae Donley",
  "Kevin Fischer",
  "Jonas Grandt",
  "kota",
  "marc",
  "HIRO-R-B",
  "Vlevo",
  "F-3r",
].shuffle

require "app/input.rb"
require "app/sprite.rb"

require "app/artifact.rb"
require "app/camera.rb"
require "app/cards.rb"
require "app/collision.rb"
require "app/boss.rb"
require "app/constants.rb"
require "app/difficulty.rb"
require "app/enemy.rb"
require "app/familiar.rb"
require "app/fireworks.rb"
require "app/game_setting.rb"
require "app/hud.rb"
require "app/legged_creature.rb"
require "app/level.rb"
require "app/level_generation/maze_generator.rb"
require "app/level_generation/pathfinding_graph.rb"
require "app/level_generation/spawn_locations.rb"
require "app/level_generation/wall.rb"
require "app/long_calculation.rb"
require "app/mana_chip.rb"
require "app/menu.rb"
require "app/minimap.rb"
require "app/particle_system.rb"
require "app/pathfinding.rb"
require "app/player.rb"
require "app/scene.rb"
require "app/sound.rb"
require "app/text.rb"
require "app/timer.rb"
require "app/effects/smoke_effect.rb"
require "app/effects/fireworks_effect.rb"
require "app/scenes/game_over.rb"
require "app/scenes/gameplay.rb"
require "app/scenes/level_generation.rb"
require "app/scenes/main_menu.rb"
require "app/scenes/paused.rb"
require "app/scenes/settings.rb"
require "app/scenes/win.rb"

# NOTE: add all requires above this

require "app/tick.rb"
