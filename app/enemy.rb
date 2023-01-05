ENEMY_BASIC = {
  w: 24,
  h: 24,
  angle: 0,
  health: 1,
  max_health: 1,
  path: Sprite.for(:enemy),
  min_exp_drop: 0,
  max_exp_drop: 2,
  speed: 2,
  body_power: 1,
}
ENEMY_SUPER = {
  path: Sprite.for(:enemy_super),
  w: 32,
  h: 32,
  health: 3,
  max_health: 3,
  speed: 3,
  min_exp_drop: 3,
  max_exp_drop: 6,
  body_power: 3,
}
ENEMY_KING = {
  path: Sprite.for(:enemy_king),
  w: 64,
  h: 64,
  health: 32,
  max_health: 32,
  speed: 4,
  min_exp_drop: 24,
  max_exp_drop: 32,
  body_power: 4,
}

ENEMY_SPAWN_LOCS = [
  { x: -100, y: -100 }, # bottom left
  { x: -100, y: 360 }, # middle left
  { x: -100, y: 820 }, # upper left
  { x: 1380, y: -100 }, # bottom right
  { x: 1380, y: 360 }, # middle right
  { x: 1380, y: 820 }, # upper right
  { x: 640, y: -10 }, # bottom middle
  { x: 640, y: 820 }, # top middle
]

# enemy `type` for overriding default algorithm:
# - :basic
# - :super
# - :king
def spawn_enemy(args, type = nil)
  enemy = ENEMY_BASIC.merge(ENEMY_SPAWN_LOCS.sample)

  case type
  when :basic
    # no-op, already got a basic
  when :super
    enemy.merge!(ENEMY_SUPER)
  when :king
    enemy.merge!(ENEMY_KING)
  else # the default algorithm
    super_chance = if args.state.player.level >= 8
                     50
                   elsif args.state.player.level >= 5
                     25
                   else
                     0
                   end
    if percent_chance?(super_chance)
      enemy.merge!(ENEMY_SUPER)
    end
  end

  enemy.define_singleton_method(:dead?) do
    health <= 0
  end

  args.state.enemies << enemy
  enemy
end

def tick_enemy(args, enemy)
  enemy.angle = args.geometry.angle_to(enemy, args.state.player)
  enemy.x_vel, enemy.y_vel = vel_from_angle(enemy.angle, enemy.speed)

  enemy.x += enemy.x_vel
  enemy.y += enemy.y_vel

  tick_flasher(enemy)

  if enemy.health == 1 && enemy.max_health > 1
    enemy.merge!(RED)
  end

  debug_label(args, enemy.x, enemy.y, "health: #{enemy.health}")
  debug_label(args, enemy.x, enemy.y - 14, "speed: #{enemy.speed}")
end

# the `entity` that damages the enemy _must_ have `power` or `body_power`
def damage_enemy(args, enemy, entity, sfx: :enemy_hit)
  enemy.health -= entity.power || entity.body_power
  flash(enemy, RED, 12)
  play_sfx(args, sfx) if sfx
  if enemy.health <= 0
    destroy_enemy(args, enemy)
  end
end

def destroy_enemy(args, enemy)
  args.state.enemies_destroyed += 1

  random(enemy.min_exp_drop, enemy.max_exp_drop).times do |i|
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
