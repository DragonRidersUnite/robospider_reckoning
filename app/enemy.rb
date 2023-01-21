module Enemy
  DESPAWN_RANGE = 1500
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

  class << self
    # enemy `type` for overriding default algorithm:
    # - :basic
    # - :super
    # - :king
    def spawn(args, type = nil)
      player = args.state.player
      level = args.state.level
      spot = spawn_location(args)
	  
	  return unless spot
	  
      enemy = ENEMY_BASIC.merge(spot)

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

      args.state.enemies << enemy
      enemy
    end
  
    def spawn_location(args)
      level = args.state.level
	  grid = level.grid.flatten.reject{|i| i.wall}
	  player = {
        x: args.state.player.x/level.cell_size,
        y: args.state.player.y/level.cell_size
      }
	  
      attempts = 50
      while attempts > 0
        attempts -= 1
        
	    pos = grid.sample

        dist = [(pos.x-player.x).abs, (pos.y-player.y).abs].max * level.cell_size
		if dist > 640 && dist < DESPAWN_RANGE
		  putz "#{50 - attempts} attempts"
          pos = {
            x: (pos.x + random(0.2, 0.8)) * level.cell_size,
            y: (pos.y + random(0.2, 0.8)) * level.cell_size,
          }
		  putz pos
		  putz dist
          return pos
        end
      end
	  putz "#{50 - attempts} attempts, and failed"
      return nil
    end

    def tick(args, enemy)
      enemy.angle = args.geometry.angle_to(enemy, args.state.player)
      enemy.x_vel, enemy.y_vel = vel_from_angle(enemy.angle, enemy.speed)

      enemy.x += enemy.x_vel
      enemy.y += enemy.y_vel

      tick_flasher(enemy)

      enemy.merge!(RED) if enemy.health == 1 && enemy.max_health > 1

      dist = [(enemy.x - args.state.player.x).abs, (enemy.y - args.state.player.y).abs].max
      despawn(enemy) if dist > DESPAWN_RANGE

      position_on_screen = Camera.translate(args.state.camera, enemy)
      debug_label(args, position_on_screen.x, position_on_screen.y, "health: #{enemy.health}")
      debug_label(args, position_on_screen.x, position_on_screen.y - 14, "speed: #{enemy.speed}")
    end

    # the `entity` that damages the enemy _must_ have `power` or `body_power`
    def damage(args, enemy, entity, sfx: :enemy_hit)
      enemy.health -= entity.power || entity.body_power
      flash(enemy, RED, 12)
      play_sfx(args, sfx) if sfx
      if enemy.health <= 0
        destroy(args, enemy)
      end
    end

    def destroy(args, enemy)
      despawn(enemy)
      args.state.enemies_destroyed += 1

      random(enemy.min_exp_drop, enemy.max_exp_drop).times do
        args.state.exp_chips << ExpChip.create(enemy)
      end
    end

    def despawn(enemy)
      enemy.dead = true
    end
  end
end
