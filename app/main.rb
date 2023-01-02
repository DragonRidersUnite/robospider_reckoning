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
BLACK = { r: 25, g: 25, b: 25 }
WHITE = { r: 255, g: 255, b: 255 }

DIR_DOWN = :down
DIR_UP = :up
DIR_LEFT = :left
DIR_RIGHT = :right

module Sprite
  # annoying to track but useful for reloading with +i+ in debug mode; would be
  # nice to define a different way
  SPRITES = {
    bullet: "sprites/bullet.png",
    enemy: "sprites/enemy.png",
    player: "sprites/player.png",
  }

  class << self
    def reset_all(args)
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
  args.state.scene ||= :gameplay

  send("tick_#{args.state.scene}", args)

  debug_tick(args)
end

def switch_scene(args, scene, reset: false)
  if reset
    case scene
    when :gameplay
      args.state.player = nil
      args.state.enemies = nil
    end
  end

  args.state.scene = scene
end

def tick_gameplay(args)
  args.state.player ||= begin
    p = {
      x: args.grid.w / 2,
      y: args.grid.h / 2,
      w: 32,
      h: 32,
      health: 6,
      speed: 6,
      path: Sprite.for(:player),
      bullets: [],
      bullet_delay: BULLET_DELAY,
      direction: DIR_UP,
    }.merge(WHITE)

    p.define_singleton_method(:dead) do
      health <= 0
    end

    p
  end

  args.state.enemies ||= []

  # spawn a new enemy every 5 seconds
  if args.state.tick_count % FPS * 5 == 0
    args.state.enemies << spawn_enemy(args)
  end

  tick_player(args, args.state.player)
  args.state.enemies.each { |e| tick_enemy(args, e)  }
  collide(args, args.state.player.bullets, args.state.enemies, -> (args, bullet, enemy) do
    bullet.dead = true
    enemy.dead = true
  end)
  collide(args, args.state.enemies, args.state.player, -> (args, enemy, player) do
    enemy.dead = true
    player.health -= 1
  end)
  args.state.enemies.reject! { |e| e.dead }

  if args.state.player.dead
    return switch_scene(args, :game_over)
  end

  if pause_down?(args)
    return switch_scene(args, :paused)
  end

  args.outputs.solids << { x: args.grid.left, y: args.grid.bottom, w: args.grid.w, h: args.grid.h }.merge(BLACK)
  args.outputs.sprites << [args.state.player, args.state.player.bullets, args.state.enemies]
  labels = []
  labels << label("#{TEXT.fetch(:health)}: #{args.state.player.health}", x: 40, y: args.grid.top - 40, size: SIZE_SM)
  args.outputs.labels << labels
end

def tick_paused(args)
  labels = []

  labels << label(:paused, x: args.grid.w / 2, y: args.grid.top - 200, align: ALIGN_CENTER, size: SIZE_LG)
  labels << label(:resume, x: args.grid.w / 2, y: args.grid.top - 420, align: ALIGN_CENTER, size: SIZE_SM).merge(a: args.state.tick_count % 155 + 100)

  if primary_down?(args.inputs)
    return switch_scene(args, :gameplay)
  end

  args.outputs.labels << labels
end

SIZE_LG = 10
SIZE_MD = 6
SIZE_SM = 4
SIZE_XS = 0

def tick_game_over(args)
  labels = []

  labels << label(:game_over, x: args.grid.w / 2, y: args.grid.top - 200, align: ALIGN_CENTER, size: SIZE_LG)
  labels << label(:restart, x: args.grid.w / 2, y: args.grid.top - 420, align: ALIGN_CENTER, size: SIZE_SM).merge(a: args.state.tick_count % 155 + 100)

  if primary_down?(args.inputs)
    return switch_scene(args, :gameplay, reset: true)
  end

  args.outputs.labels << labels
end

def label(value_or_key, x:, y:, align: ALIGN_LEFT, size: SIZE_MD, color: WHITE)
  text = if value_or_key.is_a?(Symbol)
    TEXT.fetch(value_or_key)
  else
    value_or_key
  end

  {
    text: text,
    x: x,
    y: y,
    alignment_enum: align,
    size_enum: size,
  }.merge(color)
end

TEXT = {
  game_over: "Game Over",
  health: "Health",
  paused: "Paused",
  restart: "Shoot to Restart",
  resume: "Shoot to Resume",
}

def collide(args, col1, col2, callback)
  col1 = [col1] unless col1.is_a?(Array)
  col2 = [col2] unless col2.is_a?(Array)

  col1.each do |i|
    col2.each do |j|
      if !i.dead && !j.dead
        if i.intersect_rect?(j)
          callback.call(args, i, j)
        end
      end
    end
  end
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

def spawn_enemy(args)
  {
    x: [args.grid.left + 10, args.grid.right - 10].sample,
    y: [args.grid.top + 10, args.grid.bottom - 10].sample,
    w: 24,
    h: 24,
    angle: 0,
    path: Sprite.for(:enemy),
    dead: false,
    speed: 4,
  }
end

def tick_enemy(args, enemy)
  enemy.angle = args.geometry.angle_to(enemy, args.state.player)
  enemy.x_vel, enemy.y_vel = vel_from_angle(enemy.angle, enemy.speed)

  enemy.x += enemy.x_vel
  enemy.y += enemy.y_vel

  debug_label(args, enemy.x, enemy.y, "speed: #{enemy.speed}")
end

# +angle+ is expected to be in degrees with 0 being facing right
def vel_from_angle(angle, speed)
  [speed * Math.cos(deg_to_rad(angle)), speed * Math.sin(deg_to_rad(angle))]
end

def deg_to_rad(deg)
  (deg * Math::PI / 180).round(4)
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

PAUSE_KEYS= [:escape, :p]
def pause_down?(inputs)
  PAUSE_KEYS.any? { |k| inputs.keyboard.key_down.send(k) } ||
    inputs.controller_one.key_down&.start
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
    Sprite.reset_all(args)
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
