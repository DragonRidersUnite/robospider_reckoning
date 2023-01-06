# EXQUISITE CORPS
# ~a collaborative jam of chaos~

# add your name to this array!
CREDITS = [
  "Brett Chalupa",
].shuffle

require "app/sprite.rb"
require "app/constants.rb"
require "app/enemy.rb"
require "app/exp_chip.rb"
require "app/familiar.rb"
require "app/menu.rb"
require "app/player.rb"
require "app/scene.rb"
require "app/game_setting.rb"
require "app/sound.rb"
require "app/text.rb"

require "app/scenes/game_over.rb"
require "app/scenes/gameplay.rb"
require "app/scenes/main_menu.rb"
require "app/scenes/paused.rb"
require "app/scenes/settings.rb"

# NOTE: add all requires above this

require "app/tick.rb"
