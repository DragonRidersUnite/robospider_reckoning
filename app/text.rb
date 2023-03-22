# Why put our text in a Hash? It makes it easier to proofread when near each
# other, makes the game easier to localize, and it's easier to manage than
# scouring the codebase.
#
# Don't access via this constant! Use the `#text` method instead.
TEXT = {
  back: "Back",
  controls_title: "Controls",
  controls_keyboard: "WASD/Arrows to move | J/Z/Space to confirm & shoot | Esc/P to pause",
  controls2_keyboard: "C+V, U+I, H+L to swap cards, M to toggle minimap",
  controls_gamepad: "Stick/D-Pad to move | A to confirm & shoot | Start to pause",
  controls2_gamepad: "L+R bumpers or triggers to swap cards, Y to toggle minimap",
  enemies_destroyed: "Enemies Destroyed",
  exp_to_next_level: "Exp to Next Level",
  fullscreen: "Fullscreen",
  game_over: "Game Over",
  generating_level: "Generating Level",
  health: "Health",
  mana: "Mana",
  level: "Level",
  lu_familiar_spawned: "Familiar spawned!",
  lu_familiar_speed_increased: "Familiar speed increased!",
  lu_fp_dual_shot: "Dual shot!",
  lu_fp_tri_shot: "Tri shot!",
  lu_fp_quad_shot: "Quad shot!",
  lu_fp_range_increased: "Bullet range increased!",
  lu_player_exp_magnetism_increased: "Experience pick up distance increased!",
  lu_player_fire_rate_increased: "Player fire rate increased!",
  lu_player_speed_increased: "Player speed increased!",
  made_by: "A game by:",
  off: "OFF",
  on: "ON",
  paused: "Paused",
  quit: "Quit",
  restart: "Shoot to Restart",
  retry: "Shoot to Play Again",
  resume: "Resume",
  return_to_main_menu: "Return to Main Menu",
  settings: "Settings",
  sfx: "Sound Effects",
  start: "Start",
  win: "You Win!",
  difficulty: "Difficulty",
  easy: "Grandma's House",
  normal: "The Real World",
  hard: "The Hunger Games",
}

# Gets the text for the passed in `key`. Raises if it does not exist. We don't
# want missing text!
def text(key)
  TEXT.fetch(key)
end

SIZE_XS = 0
SIZE_SM = 4
SIZE_MD = 6
SIZE_LG = 10

FONT_REGULAR = "fonts/Atkinson-Hyperlegible-Regular-102.ttf"
FONT_ITALIC = "fonts/Atkinson-Hyperlegible-Italic-102.ttf"
FONT_BOLD = "fonts/Atkinson-Hyperlegible-Bold-102.ttf"
FONT_BOLD_ITALIC = "fonts/Atkinson-Hyperlegible-BoldItalic-102.ttf"

# Friendly method with sensible defaults for creating DRGTK label data
# structures.
def label(value_or_key, x:, y:, align: ALIGN_LEFT, size: SIZE_MD, color: WHITE, font: FONT_REGULAR)
  {
    text: value_or_key.is_a?(Symbol) ? text(value_or_key) : value_or_key,
    x: x,
    y: y,
    alignment_enum: align,
    size_enum: size,
    font: font,
  }.label!(color)
end
