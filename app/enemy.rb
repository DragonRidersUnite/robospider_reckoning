module Enemy
  DESPAWN_RANGE = 1200
  UPDATE_RANGE = 640
  ENEMY_BASIC = {
    type: :basic,
    angle: 0,
    target: false,
    mode: :idle,
    attention_span: 40,
    attention_counter: 0,
    delay_time: 30,
    delay_counter: 0,
    w: 24,
    h: 24,
    health: 1,
    base_health: 1,
    max_health: 1,
    path: Sprite.for(:enemy),
    min_mana_drop: 1,
    max_mana_drop: 4,
    speed: 3,
    body_power: 1,
    xp: 1,
  }
  ENEMY_SUPER = {
    type: :super,
    path: Sprite.for(:enemy_super),
    w: 32,
    h: 32,
    health: 3,
    base_health: 3,
    max_health: 5,
    speed: 4,
    min_mana_drop: 4,
    max_mana_drop: 10,
    body_power: 3,
    xp: 5,
  }
  ENEMY_KING = {
    type: :king,
    path: Sprite.for(:enemy_king),
    w: 64,
    h: 64,
    health: 32,
    base_health: 32,
    max_health: 100,
    speed: 2,
    min_mana_drop: 20,
    max_mana_drop: 30,
    body_power: 10,
    xp: 20,
    mode: :hunting
  }

  class << self
    # enemy `type` for overriding default algorithm:
    # - :basic
    # - :super
    # - :king
    def spawn(args, type = nil)
      player = args.state.player
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
        super_chance = 10 * player.level
        enemy.merge!(ENEMY_SUPER) if percent_chance?(super_chance)
      end

      health = min((enemy.base_health * player.level * rand).ceil, enemy.max_health)
      enemy.merge!({ health: health, max_health: health })
      args.state.enemies << enemy
      enemy
    end

    def spawn_location(args)
      level = args.state.level
      grid = level.grid.flatten.reject(&:wall)

      player = {
        x: args.state.player.x/level.cell_size,
        y: args.state.player.y/level.cell_size
      }

      attempts = -1
      while (attempts += 1) < 20
        pos = grid.sample

        dist = max((pos.x-player.x).abs, (pos.y-player.y).abs) * level.cell_size
        if dist > 640 && dist < DESPAWN_RANGE
          pos = {
            x: (pos.x + random(0.2, 0.8)) * level.cell_size,
            y: (pos.y + random(0.2, 0.8)) * level.cell_size,
          }
          putz "Took #{attempts} attempts to spawn enemy." if debug?
          return pos
        end
      end
      putz "Could not spawn enemy." if debug?
      return nil
    end

    # the `entity` that damages the enemy _must_ have `power` or `body_power`
    def damage(args, enemy, entity, sfx: :enemy_hit)
      enemy.health -= entity.power || entity.body_power
      flash(enemy, RED, 12)
      play_sfx(args, sfx) if sfx
      destroy(args, enemy) if enemy.health <= 0
    end

    def destroy(args, enemy)
      despawn(enemy)
      args.state.enemies_destroyed += 1

      random(enemy.min_mana_drop, enemy.max_mana_drop).round.times do
        args.state.mana_chips << ManaChip.create(enemy)
      end
    end

    def despawn(enemy)
      enemy.dead = true
    end

    def line_of_sight(level, enemy, player)
      # maze is mostly corridors, so it is a very fair assumption that
      # enemy will not ever see the player if they don't share at least one axis
      if enemy.x == player.x
        lower, higher = [enemy.y, player.y].sort
        same = enemy.x
        i = lower
        v = true
      elsif enemy.y == player.y
        lower, higher = [enemy.x, player.x].sort
        same = enemy.y
        i = lower
      else
        return false
      end

      return false if (higher - lower > 4) # visual range of enemy down a corridor

      while (i+=1) <= higher+1
        return false if (v ? level[same][i-1][:wall] : level[i-1][same][:wall])
      end
      return true
    end

    def tick(args, enemy, player, level)
      # Stop doing calculations if we're out of sight, except for kings
      dist = enemy.type == :king ? 0 : max((enemy.x - player.x).abs, (enemy.y - player.y).abs)
      if dist > DESPAWN_RANGE
        despawn(enemy)
      elsif dist < UPDATE_RANGE
        send(enemy.mode, args, enemy, player, level)
        enemy.delay_counter += 1

        tick_flasher(enemy)
        enemy.merge!(RED) if enemy.health == 1 && enemy.max_health > 1

        debug_block do
          screen = Camera.translate(args.state.camera, enemy)

          debug_label(args, screen.x, screen.y, "health: #{enemy.health}")
          debug_label(args, screen.x, screen.y - 14, "speed: #{enemy.mode}")
        end
      end
    end

    # BEHAVIORS
    def idle(args, enemy, player, level)
      return unless pass_delay?(enemy)
      enemy.delay_counter = 0

      if see_player?(enemy, player, level)
        enemy.target = player
        return enemy.mode = :chasing
      elsif enemy.type == :king # This guy always hunts
        enemy.target = player
        return enemy.mode = :hunting
      elsif rand(2) == 0 # NOTE: log(0.05)/log(1.0-chance) =~ occurences to get 95% chance of this activating
                         # log(0.05)/log(1.0-0.5) =~ 4.3 | At 30 delay (2 per/sec) it'll happen before ~2 seconds or at worst, after
        enemy.target = { x: enemy.x + random(-400, 400), y: enemy.y + random(-400, 400) }
        return enemy.mode = :wandering
      end
    end

    def wandering(args, enemy, player, level)
      if pass_delay?(enemy)
        enemy.delay_counter = 0

        if see_player?(enemy, player, level)
          enemy.target = player
          return enemy.mode = :chasing
        elsif pass_attention?(enemy) && rand(2) == 0
          enemy.attention_counter = 0
          enemy.target = false
          return enemy.mode = :idle
        elsif rand(40) == 0 # Low chance a wandering enemy will catch your scent!
          return enemy.mode = :hunting
        end
      end

      enemy.attention_counter += 1

      do_chase(args, enemy)
    end

    def chasing(args, enemy, player, level)
      if pass_delay?(enemy)
        enemy.delay_counter = 0

        if see_player?(enemy, player, level)
          enemy.attention_counter = 0
          enemy.target = player
        elsif pass_attention?(enemy) && rand(2) == 0
          enemy.attention_counter = 0
          enemy.delay_counter = -60
          enemy.target = false
          return enemy.mode = :idle
        end
      end

      enemy.attention_counter += 1

      do_chase(args, enemy)
    end

    def hunting(args, enemy, player, level)
      if see_player?(enemy, player, level)
        enemy.path_points = nil
        enemy.delay_counter = 0
        enemy.target = player
        return enemy.mode = :chasing
      elsif pass_delay?(enemy)
        enemy.path_points = Pathfinding.find_path(
          level[:pathfinding_graph],
          start: { x: ((enemy.x + enemy.w / 2) / level.cell_size).floor,
                   y: ((enemy.y + enemy.h / 2) / level.cell_size).floor },
          goal: { x: ((player.x + player.w / 2) / level.cell_size).floor,
                  y: ((player.y + player.h / 2) / level.cell_size).floor }
        )
        enemy.path_points.shift # First point is redundant?
        enemy.delay_counter = -3.seconds # Don't need to update the path a lot
        enemy.target = false
      end

      unless do_chase(args, enemy)
        if enemy.path_points && !enemy.path_points.empty?
          next_cell = enemy.path_points.shift
          enemy.target = { x: (next_cell.x + 0.5) * level.cell_size,
                           y: (next_cell.y + 0.5) * level.cell_size }
        end
      end
    end

    # BEHAVIOR Helpers
    def pass_delay?(enemy)
      enemy.delay_counter >= enemy.delay_time
    end

    def pass_attention?(enemy)
      enemy.attention_counter >= enemy.attention_span
    end

    def at_target?(enemy)
      ((enemy.x - enemy.target.x) ** 2 + (enemy.y - enemy.target.y) ** 2) < enemy.speed ** 2
    end

    def see_player?(enemy, player, level)
      enemy_pos  = { x: enemy.x.idiv(level.cell_size),  y: enemy.y.idiv(level.cell_size) }
      player_pos = { x: player.x.idiv(level.cell_size), y: player.y.idiv(level.cell_size) }

      line_of_sight(level.grid, enemy_pos, player_pos)
    end

    def do_chase(args, enemy)
      return false unless enemy.target

      if at_target?(enemy)
        enemy.x = enemy.target.x
        enemy.y = enemy.target.y

        false
      else
        enemy.angle = args.geometry.angle_to(enemy, enemy.target)
        enemy.x_vel, enemy.y_vel = vel_from_angle(enemy.angle, enemy.speed)

        enemy.x += enemy.x_vel
        enemy.y += enemy.y_vel

        true
      end
    end
  end
end
