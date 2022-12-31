FPS = 60
ALIGN_LEFT = 0
ALIGN_CENTER = 1
ALIGN_RIGHT = 2
BLEND_NONE = 0
BLEND_ALPHA = 1
BLEND_ADDITIVE = 2
BLEND_MODULO = 3
BLEND_MULTIPLY = 4

TRUE_BLACK = { r: 0, g: 0, b: 0 }
WHITE = { r: 255, g: 255, b: 255 }

DIR_DOWN = :down
DIR_UP = :up
DIR_LEFT = :left
DIR_RIGHT = :right

module Sprite
  # annoying to track but useful for reloading with +i+ in debug mode; would be
  # nice to define a different way
  SPRITES = {
    player: "sprites/player.png",
    bullet: "sprites/bullet.png",
  }

  class << self
    def reset_all
      SPRITES.each { |_, v| args.gtk.reset_sprite(v) }
    end

    def for(key)
      SPRITES.fetch(key)
    end
  end
end

# Code that only gets run once on game start
def init(args)
end

def tick(args)
  init(args) if args.state.tick_count == 0

  args.outputs.background_color = TRUE_BLACK.values

  args.state.player ||= {
    x: args.grid.w / 2,
    y: args.grid.h / 2,
    w: 32,
    h: 32,
    speed: 6,
    path: Sprite.for(:player),
    bullets: [],
    bullet_delay: BULLET_DELAY,
    direction: DIR_UP,
  }.merge(WHITE)

  tick_player(args, args.state.player)

  args.outputs.sprites << [args.state.player, args.state.player.bullets]

  debug_tick(args)
end

BULLET_DELAY = 10
BULLET_SIZE = 10
def tick_player(args, player)
  firing = primary_down_or_held?(args.inputs)

  if args.inputs.down
    player.y -= player.speed
    if !firing
      player.direction = DIR_DOWN
    end
  elsif args.inputs.up
    player.y += player.speed
    if !firing
      player.direction = DIR_UP
    end
  end

  if args.inputs.left
    player.x -= player.speed
    if !firing
      player.direction = DIR_LEFT
    end
  elsif args.inputs.right
    player.x += player.speed
    if !firing
      player.direction = DIR_RIGHT
    end
  end

  player.angle = angle_for_dir(player.direction)
  player.bullet_delay += 1

  if player.bullet_delay >= BULLET_DELAY && firing
    player.bullets << {
      x: player.x + player.w / 2 - BULLET_SIZE / 2,
      y: player.y + player.h / 2 - BULLET_SIZE / 2,
      w: BULLET_SIZE,
      h: BULLET_SIZE,
      speed: 12,
      direction: player.direction,
      angle: player.angle,
      dead: false,
      path: Sprite.for(:bullet),
    }.merge(WHITE)
    player.bullet_delay = 0
  end

  player.bullets.each do |b|
    case b.direction
    when DIR_UP
      b.y += b.speed
    when DIR_DOWN
      b.y -= b.speed
    when DIR_LEFT
      b.x -= b.speed
    when DIR_RIGHT
      b.x += b.speed
    end

    if out_of_bounds?(args.grid, b)
      b.dead = true
    end
  end

  player.bullets.reject! { |b| b.dead }
  debug_label(args, player.x, player.y, "dir: #{player.direction}")
  debug_label(args, player.x, player.y - 14, "angle: #{player.angle}")
  debug_label(args, player.x, player.y - 28, "bullets: #{player.bullets.length}")
end

# Returns degrees
def angle_for_dir(dir)
  case dir
  when DIR_RIGHT
    0
  when DIR_LEFT
    180
  when DIR_UP
    90
  when DIR_DOWN
    270
  else
    error("invalid dir: #{dir}")
  end
end

def out_of_bounds?(grid, rect)
  rect.x > grid.right ||
    rect.x + rect.w < grid.left ||
    rect.y > grid.top ||
    rect.y + rect.h < grid.bottom
end

def error(msg)
  raise StandardError.new(msg)
end

PRIMARY_KEYS = [:j, :z]
def primary_down?(inputs)
  PRIMARY_KEYS.any? { |k| inputs.keyboard.key_down.send(k) } ||
    inputs.controller_one.key_down&.a
end
def primary_down_or_held?(inputs)
  primary_down?(inputs) ||
    PRIMARY_KEYS.any? { |k| inputs.keyboard.key_held.send(k) } ||
    (inputs.controller_one.connected &&
     inputs.controller_one.key_held.a)
end

# The version of your game defined in `metadata/game_metadata.txt`
def version
  $gtk.args.cvars['game_metadata.version'].value
end

def debug?
  @debug ||= !$gtk.production
end

def debug_tick(args)
  return unless debug?

  debug_label(args, args.grid.right - 24, args.grid.top, "#{args.gtk.current_framerate.round}")

  if args.inputs.keyboard.key_down.i
    Sprite.reset_all
    args.gtk.notify!("Sprites reloaded")
  end

  if args.inputs.keyboard.key_down.r
    $gtk.reset
  end

  if args.inputs.keyboard.key_down.zero
    args.state.render_debug_details = !args.state.render_debug_details
  end
end

def debug_label(args, x, y, text)
  return unless debug?
  return unless args.state.render_debug_details

  args.outputs.debug << { x: x, y: y, text: text }.merge(WHITE).label!
end
