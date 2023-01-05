# add your name to this array!
CREDITS = [
  "Brett Chalupa",
].shuffle

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
RED = { r: 231, g: 89, b: 82 }

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
    exp_chip: "sprites/exp_chip.png",
    familiar: "sprites/familiar.png",
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
  load_settings(args)
  args.gtk.hide_cursor
end

def tick(args)
  init(args) if args.state.tick_count == 0

  # this looks good on non 16:9 resolutions; game background is different
  args.outputs.background_color = TRUE_BLACK.values
  args.state.has_focus ||= true
  args.state.scene ||= :main_menu

  send("tick_scene_#{args.state.scene}", args)

  debug_tick(args)
end

def tick_scene_main_menu(args)
  options = [
    {
      key: :start,
      on_select: -> (args) { switch_scene(args, :gameplay, reset: true) }
    },
    {
      key: :settings,
      on_select: -> (args) { switch_scene(args, :settings, reset: true, return_to: :main_menu) }
    },
  ]

  if args.gtk.platform?(:desktop)
    options << {
      key: :quit,
      on_select: -> (args) { args.gtk.request_quit }
    }
  end

  tick_menu(args, :main_menu, options)

  labels = []
  labels << label(
    title, x: args.grid.w / 2, y: args.grid.top - 100,
    size: SIZE_LG, align: ALIGN_CENTER)
  labels << label(
    "#{text(:made_by)} #{CREDITS.join(', ')}",
    x: args.grid.left + 24, y: 48,
    size: SIZE_XS, align: ALIGN_LEFT)

  args.outputs.labels << labels
end

def switch_scene(args, scene, reset: false, return_to: nil)
  args.state.scene_to_return_to = return_to if return_to

  if scene == :back && args.state.scene_to_return_to
    scene = args.state.scene_to_return_to
    args.state.scene_to_return_to = nil
  end

  if reset
    case scene
    when :gameplay
      args.state.player = nil
      args.state.enemies = nil
      args.state.enemies_destroyed = nil
      args.state.exp_chips = nil
    else
      args.state.send(scene)&.current_option_i = nil
      args.state.send(scene)&.hold_delay = nil
    end
  end

  args.state.scene = scene
end

# FP = Fire Pattern
FP_SINGLE = :single
FP_DUAL = :dual
FP_TRI = :tri
FP_QUAD = :quad

def tick_scene_gameplay(args)
  args.state.player ||= begin
    p = {
      x: args.grid.w / 2,
      y: args.grid.h / 2,
      w: 32,
      h: 32,
      health: 6,
      speed: 4,
      level: 1,
      path: Sprite.for(:player),
      exp_to_next_level: LEVEL_EXP_DIFF[2],
      bullets: [],
      familiars: [],
      exp_chip_magnetic_dist: 50,
      bullet_delay: INIT_BULLET_DELAY,
      bullet_delay_counter: INIT_BULLET_DELAY,
      fire_pattern: FP_SINGLE,
      direction: DIR_UP,
      invincible: false,
    }.merge(WHITE)

    p.define_singleton_method(:dead) do
      health <= 0
    end

    p
  end

  args.state.enemies ||= []
  args.state.enemies_destroyed ||= 0
  args.state.exp_chips ||= []

  if !args.state.has_focus && args.inputs.keyboard.has_focus
    args.state.has_focus = true
  elsif args.state.has_focus && !args.inputs.keyboard.has_focus
    args.state.has_focus = false
  end

  if !args.state.has_focus || pause_down?(args)
    play_sfx(args, :select)
    return switch_scene(args, :paused, reset: true)
  end

  # spawns enemies faster when player level is higher; starts at every 12 seconds
  if args.state.tick_count % FPS * (12 - (args.state.player.level / 3).to_i) == 0
    args.state.enemies << spawn_enemy(args)
  end

  tick_player(args, args.state.player)
  args.state.enemies.each { |e| tick_enemy(args, e)  }
  args.state.exp_chips.each { |c| tick_exp_chip(args, c)  }
  collide(args, args.state.player.bullets, args.state.enemies, -> (args, bullet, enemy) do
    bullet.dead = true
    destroy_enemy(args, enemy)
  end)
  collide(args, args.state.enemies, args.state.player, -> (args, enemy, player) do
    player.health -= 1 unless player.invincible
    destroy_enemy(args, enemy, sfx: false)
    play_sfx(args, :hurt)
  end)
  collide(args, args.state.enemies, args.state.player.familiars, -> (args, enemy, familiar) do
    destroy_enemy(args, enemy, sfx: :enemy_death_by_familiar)
  end)
  collide(args, args.state.exp_chips, args.state.player, -> (args, exp_chip, player) do
    exp_chip.dead = true
    absorb_exp(args, player, exp_chip)
    play_sfx(args, :exp_chip)
  end)
  args.state.enemies.reject! { |e| e.dead }
  args.state.exp_chips.reject! { |e| e.dead }

  if args.state.player.dead
    play_sfx(args, :player_death)
    return switch_scene(args, :game_over)
  end

  args.outputs.solids << { x: args.grid.left, y: args.grid.bottom, w: args.grid.w, h: args.grid.h }.merge(BLACK)
  args.outputs.sprites << [args.state.exp_chips, args.state.player.bullets, args.state.player, args.state.enemies, args.state.player.familiars]

  labels = []
  labels << label("#{text(:health)}: #{args.state.player.health}", x: 40, y: args.grid.top - 40, size: SIZE_SM)
  labels << label("#{text(:level)}: #{args.state.player.level}", x: 40, y: args.grid.top - 72, size: SIZE_SM)
  labels << label("#{text(:enemies_destroyed)}: #{args.state.enemies_destroyed}", x: args.grid.right - 40, y: args.grid.top - 40, size: SIZE_SM, align: ALIGN_RIGHT)
  args.outputs.labels << labels
end

def destroy_enemy(args, enemy, sfx: :enemy_death)
  play_sfx(args, sfx) if sfx
  enemy.dead = true
  args.state.enemies_destroyed += 1
  rand(3).times do |i|
    args.state.exp_chips << {
      x: enemy.x + enemy.w / 2 + (-5..5).to_a.sample + i * 5,
      y: enemy.y + enemy.h / 2 + (-5..5).to_a.sample + i * 5,
      speed: 6,
      angle: rand(360),
      w: 12,
      h: 12,
      dead: false,
      exp_amount: 1,
      path: Sprite.for(:exp_chip)
    }
  end
end

def tick_scene_paused(args)
  options = [
    {
      key: :resume,
      on_select: -> (args) { switch_scene(args, :gameplay) }
    },
    {
      key: :settings,
      on_select: -> (args) { switch_scene(args, :settings, reset: true, return_to: :paused) }
    },
    {
      key: :return_to_main_menu,
      on_select: -> (args) { switch_scene(args, :main_menu) }
    },
  ]

  if args.gtk.platform?(:desktop)
    options << {
      key: :quit,
      on_select: -> (args) { args.gtk.request_quit }
    }
  end

  tick_menu(args, :paused, options)

  args.outputs.labels << label(:paused, x: args.grid.w / 2, y: args.grid.top - 200, align: ALIGN_CENTER, size: SIZE_LG)
end

def toggle_fullscreen(args)
  args.state.setting.fullscreen = !args.state.setting.fullscreen
  args.gtk.set_window_fullscreen(args.state.setting.fullscreen)
end

def load_settings(args)
  settings = args.gtk.read_file(settings_file)

  if settings
    settings.split(",").map { |s| s.split(":") }.to_h.each do |k, v|
      if v == "true"
        v = true
      elsif v == "false"
        v = false
      end
      args.state.setting[k.to_sym] = v
    end
  else
    args.state.setting.sfx = true
    args.state.setting.fullscreen = false
  end

  if args.state.setting.fullscreen
    args.gtk.set_window_fullscreen(args.state.setting.fullscreen)
  end
end

def save_settings(args)
  args.gtk.write_file(
    settings_file,
    settings_for_save(open_entity_to_hash(args.state.setting))
  )
end

def open_entity_to_hash(open_entity)
  open_entity.as_hash.except(:entity_id, :entity_name, :entity_keys_by_ref, :__thrash_count__)
end

# returns a string of a hash of settings in the following format:
# key1=val1,key2=val2
# `settings` should be a hash of keys and vals to be saved
def settings_for_save(settings)
  settings.map do |k, v|
    "#{k}:#{v}"
  end.join(",")
end

def settings_file
  "settings#{ debug? ? '-debug' : nil}.txt"
end

def tick_scene_settings(args)
  options = [
    {
      key: :sfx,
      kind: :toggle,
      setting_val: args.state.setting.sfx,
      on_select: -> (args) { args.state.setting.sfx = !args.state.setting.sfx; save_settings(args) }
    },
    {
      key: :back,
      on_select: -> (args) { switch_scene(args, :back) }
    },
  ]

  if args.gtk.platform?(:desktop)
    options.insert(options.length - 1, {
      key: :fullscreen,
      kind: :toggle,
      setting_val: args.state.setting.fullscreen,
      on_select: -> (args) { toggle_fullscreen(args); save_settings(args) }
    })
  end

  tick_menu(args, :settings, options)

  args.outputs.labels << label(:settings, x: args.grid.w / 2, y: args.grid.top - 200, align: ALIGN_CENTER, size: SIZE_LG)
end

def tick_scene_game_over(args)
  labels = []

  labels << label(:game_over, x: args.grid.w / 2, y: args.grid.top - 200, align: ALIGN_CENTER, size: SIZE_LG)
  labels << label(:restart, x: args.grid.w / 2, y: args.grid.top - 420, align: ALIGN_CENTER, size: SIZE_SM).merge(a: args.state.tick_count % 155 + 100)
  labels << label("#{text(:enemies_destroyed)}: #{args.state.enemies_destroyed}", x: args.grid.w / 2, y: args.grid.top - 320, size: SIZE_SM, align: ALIGN_CENTER)

  if primary_down?(args.inputs)
    return switch_scene(args, :gameplay, reset: true)
  end

  args.outputs.labels << labels
end

TEXT = {
  back: "Back",
  enemies_destroyed: "Enemies Destroyed",
  fullscreen: "Fullscreen",
  game_over: "Game Over",
  health: "Health",
  level: "Level",
  lu_familiar_spawned: "Familiar spawned!",
  lu_familiar_speed_increased: "Familiar speed increased!",
  lu_fp_dual_shot: "Dual shot!",
  lu_fp_tri_shot: "Tri shot!",
  lu_fp_quad_shot: "Quad shot!",
  lu_player_exp_magnetism_increased: "Experience pick up distance increased!",
  lu_player_fire_rate_increased: "Player fire rate increased!",
  lu_player_speed_increased: "Player speed increased!",
  made_by: "A game by",
  off: "OFF",
  on: "ON",
  paused: "Paused",
  quit: "Quit",
  restart: "Shoot to Restart",
  resume: "Resume",
  return_to_main_menu: "Return to Main Menu",
  settings: "Settings",
  sfx: "Sound Effects",
  start: "Start",
}

SIZE_XS = 0
SIZE_SM = 4
SIZE_MD = 6
SIZE_LG = 10

def text(key)
  TEXT.fetch(key)
end

def label(value_or_key, x:, y:, align: ALIGN_LEFT, size: SIZE_MD, color: WHITE)
  text = if value_or_key.is_a?(Symbol)
           text(value_or_key)
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

INIT_BULLET_DELAY = 10
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
  player.bullet_delay_counter += 1

  def bullet(player, angle)
    {
      x: player.x + player.w / 2 - BULLET_SIZE / 2,
      y: player.y + player.h / 2 - BULLET_SIZE / 2,
      w: BULLET_SIZE,
      h: BULLET_SIZE,
      angle: angle,
      speed: 12,
      dead: false,
      path: Sprite.for(:bullet),
    }.merge(WHITE)
  end

  if player.bullet_delay_counter >= player.bullet_delay && firing
    bullets = []
    case player.fire_pattern
    when FP_SINGLE
      bullets << bullet(player, player.angle)
    when FP_DUAL
      bullets << bullet(player, player.angle)
      bullets << bullet(player, opposite_angle(player.angle))
    when FP_TRI
      bullets << bullet(player, player.angle)
      bullets << bullet(player, add_to_angle(player.angle, -30))
      bullets << bullet(player, add_to_angle(player.angle, 30))
    when FP_QUAD
      bullets << bullet(player, player.angle)
      bullets << bullet(player, opposite_angle(player.angle))
      bullets << bullet(player, add_to_angle(player.angle, -30))
      bullets << bullet(player, add_to_angle(player.angle, 30))
    end

    play_sfx(args, :shoot)
    player.bullet_delay_counter = 0
    player.bullets.concat(bullets)
  end

  player.bullets.each do |b|
    x_vel, y_vel = vel_from_angle(b.angle, b.speed)
    b.x += x_vel
    b.y += y_vel

    if out_of_bounds?(args.grid, b)
      b.dead = true
    end
  end

  player.bullets.reject! { |b| b.dead }

  player.familiars.each { |f| tick_familiar(args, player, f) }

  if player.health == 1
    player.merge!(RED)
  end

  debug_label(args, player.x, player.y, "dir: #{player.direction}")
  debug_label(args, player.x, player.y - 14, "angle: #{player.angle}")
  debug_label(args, player.x, player.y - 28, "bullets: #{player.bullets.length}")
  debug_label(args, player.x, player.y - 42, "exp 2 nxt lvl: #{player.exp_to_next_level}")
  debug_label(args, player.x, player.y - 54, "bullet delay: #{player.bullet_delay}")
end

def spawn_familiar(player, dist_from_player:, speed: 18)
  player.familiars << {
    x: player.x + 10,
    y: player.y,
    w: 18,
    h: 18,
    speed: speed,
    dist_from_player: dist_from_player,
    path: Sprite.for(:familiar),
  }
end

def tick_familiar(args, player, familiar)
  rotator = args.state.tick_count / familiar.speed
  familiar.x = player.x + player.w / 2 + Math.sin(rotator) * familiar.dist_from_player
  familiar.y = player.y + player.h / 2 + Math.cos(rotator) * familiar.dist_from_player
  familiar.angle = args.geometry.angle_to(player, familiar)
  familiar
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
    speed: 2,
  }
end

def tick_enemy(args, enemy)
  enemy.angle = args.geometry.angle_to(enemy, args.state.player)
  enemy.x_vel, enemy.y_vel = vel_from_angle(enemy.angle, enemy.speed)

  enemy.x += enemy.x_vel
  enemy.y += enemy.y_vel

  debug_label(args, enemy.x, enemy.y, "speed: #{enemy.speed}")
end

def tick_exp_chip(args, exp_chip)
  player = args.state.player
  if args.geometry.distance(exp_chip, player) <= player.exp_chip_magnetic_dist
    exp_chip.angle = args.geometry.angle_to(exp_chip, player)
    exp_chip.speed = player.speed + 1
  end

  if exp_chip.speed >= 1
    exp_chip.x_vel, exp_chip.y_vel = vel_from_angle(exp_chip.angle, exp_chip.speed)

    exp_chip.x += exp_chip.x_vel
    exp_chip.y += exp_chip.y_vel
    exp_chip.speed -= 1
  end
end

def absorb_exp(args, player, exp_chip)
  player.exp_to_next_level -= exp_chip.exp_amount

  # level up every 10 points
  if (player.exp_to_next_level <= 0)
    level_up(args, player)
  end
end

LEVEL_EXP_DIFF = {
  2 => 10,
  3 => 15,
  4 => 18,
  5 => 25,
  6 => 26,
  7 => 30,
  8 => 33,
  9 => 35,
  10 => 38,
}

def level_up(args, player)
  player.level += 1
  player.exp_to_next_level = LEVEL_EXP_DIFF[player.level] || 100 # 100 is just a fail-safe ceiling
  play_sfx(args, :level_up)

  case player.level
  when 2
    spawn_familiar(player, dist_from_player: 66)
    args.gtk.notify!(text(:lu_familiar_spawned))
  when 3
    # familiar speed is weird and decreasing it makes it faster
    player.familiars.each do |f|
      f.speed -= 3
    end
    args.gtk.notify!(text(:lu_familiar_speed_increased))
  when 4
    player.speed += 2
    args.gtk.notify!(text(:lu_player_speed_increased))
  when 5
    player.exp_chip_magnetic_dist *= 2
    args.gtk.notify!(text(:lu_player_exp_magnetism_increased))
  when 6
    player.fire_pattern = FP_DUAL
    args.gtk.notify!(text(:lu_fp_dual_shot))
  when 7
    player.fire_pattern = FP_TRI
    args.gtk.notify!(text(:lu_fp_tri_shot))
  when 8
    player.bullet_delay -= 2
    args.gtk.notify!(text(:lu_player_fire_rate_increased))
  when 9
    player.fire_pattern = FP_QUAD
    args.gtk.notify!(text(:lu_fp_quad_shot))
  when 10
    # quad shot
  when 11
    # faster familiars
  end
end

# +angle+ is expected to be in degrees with 0 being facing right
def vel_from_angle(angle, speed)
  [speed * Math.cos(deg_to_rad(angle)), speed * Math.sin(deg_to_rad(angle))]
end

# returns diametrically opposed angle
# uses degrees
def opposite_angle(angle)
  add_to_angle(angle, 180)
end

# returns a new angle from the og `angle` one summed with the `diff`
# degrees! of course
def add_to_angle(angle, diff)
  ((angle + diff) % 360).abs
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

def title
  $gtk.args.cvars['game_metadata.gametitle'].value
end

def debug?
  @debug ||= !$gtk.production
end

def debug_tick(args)
  return unless debug?

  debug_label(args, args.grid.right - 24, args.grid.top, "#{args.gtk.current_framerate.round}")

  if args.inputs.keyboard.key_down.i
    play_sfx(args, :select)
    Sprite.reset_all(args)
    args.gtk.notify!("Sprites reloaded")
  end

  if args.inputs.keyboard.key_down.r
    play_sfx(args, :select)
    $gtk.reset
  end

  if args.inputs.keyboard.key_down.zero
    play_sfx(args, :select)
    args.state.render_debug_details = !args.state.render_debug_details
  end

  player = args.state.player
  if player
    if args.inputs.keyboard.key_down.one
      play_sfx(args, :select)
      level_up(args, player)
    end

    if args.inputs.keyboard.key_down.two
      play_sfx(args, :select)
      player.invincible = !player.invincible
      args.gtk.notify!("Player invincibility toggled")
    end
    if player.invincible && args.state.scene == :gameplay
      args.outputs.labels << label("inv", x: player.x + player.w / 2, y: player.y + player.h + 16, align: ALIGN_CENTER, size: SIZE_XS)
    end
  end
end

def debug_label(args, x, y, text)
  return unless debug?
  return unless args.state.render_debug_details

  args.outputs.debug << { x: x, y: y, text: text }.merge(WHITE).label!
end

# Updates and renders a list of options that get passed through.
#
# +options+ data structure:
# [
#   {
#     text: "some string",
#     on_select: -> (args) { "do some stuff in this lambda" }
#   }
# ]
def tick_menu(args, state_key, options)
  args.state.send(state_key).current_option_i ||= 0
  args.state.send(state_key).hold_delay ||= 0
  menu_state = args.state.send(state_key)

  labels = []

  options.each.with_index do |option, i|
    text = case option.kind
           when :toggle
             "#{text(option[:key])}: #{text_for_setting_val(option[:setting_val])}"
           else
             text(option[:key])
           end
    label = label(
      text,
      x: args.grid.w / 2,
      y: 360 + (options.length - i * 52),
      align: ALIGN_CENTER,
      size: SIZE_MD
    )
    label_size = args.gtk.calcstringbox(label.text, label.size_enum)
    labels << label
    if menu_state.current_option_i == i
      args.outputs.solids << {
        x: label.x - (label_size[0] / 1.4) - 24 + (Math.sin(args.state.tick_count / 8) * 4),
        y: label.y - 22,
        w: 16,
        h: 16,
      }.merge(WHITE)
    end
  end

  args.outputs.labels << labels

  move = nil
  if args.inputs.down
    move = :down
  elsif args.inputs.up
    move = :up
  else
    menu_state.hold_delay = 0
  end

  if move
    menu_state.hold_delay -= 1

    if menu_state.hold_delay <= 0
      play_sfx(args, :menu)
      index = menu_state.current_option_i
      if move == :up
        index -= 1
      else
        index += 1
      end

      if index < 0
        index = options.length - 1
      elsif index > options.length - 1
        index = 0
      end
      menu_state.current_option_i = index
      menu_state.hold_delay = 10
    end
  end

  if primary_down?(args.inputs)
    play_sfx(args, :select)
    options[menu_state.current_option_i][:on_select].call(args)
  end
end

def text_for_setting_val(val)
  case val
  when true
    text(:on)
  when false
    text(:off)
  else
    val
  end
end

def play_sfx(args, key)
  if args.state.setting.sfx
    args.outputs.sounds << "sounds/#{key}.wav"
  end
end
