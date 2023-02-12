module Enemy
  DESPAWN_RANGE = 1200
  ENEMY_BASIC = {
    type: :basic,
    angle: 0,
    target: false,
    mode: :idle,
    attention_span: 40,
    attention_counter: 0,
    delay_time: 20,
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
    min_mana_drop: 3,
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

      health = [(enemy.base_health * player.level * rand).ceil, enemy.max_health].min
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

        dist = [(pos.x-player.x).abs, (pos.y-player.y).abs].max * level.cell_size
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
      dist = enemy.type == :king ? 0 : [(enemy.x - player.x).abs, (enemy.y - player.y).abs].max
      if dist > DESPAWN_RANGE
        despawn(enemy)
      elsif dist < 640
        enemy_pos = {x: enemy.x.idiv(level.cell_size), y: enemy.y.idiv(level.cell_size)}
        player_pos = {x: player.x.idiv(level.cell_size), y: player.y.idiv(level.cell_size)}

        sees_player = line_of_sight(level.grid, enemy_pos, player_pos)

        enemy.delay_counter += 1
        if enemy.delay_counter >= enemy.delay_time
          case enemy.mode
          when :hunting
            enemy.target = player
          when :chasing
            if sees_player
              enemy.attention_counter = 0
              enemy.mode = :hunting if rand(100) == 0
            else
              enemy.attention_counter += 1
              if enemy.attention_counter >= enemy.attention_span && rand(30) == 0
                enemy.delay_counter = 0
                enemy.target = false
                enemy.mode = :idle
              end
            end
          when :wandering
            if sees_player
              enemy.delay_counter = 0
              enemy.target = player
              enemy.mode = :chasing
            end

            enemy.attention_counter += 1
            if enemy.attention_counter >= enemy.attention_span && rand(90) == 0
              enemy.delay_counter = 0
              enemy.target = false
              enemy.mode = :idle
            end
          when :idle
            if sees_player
              enemy.delay_counter = 0
              enemy.target = player
              enemy.mode = :chasing
            end

            if rand(30) == 0
              enemy.target = {x: enemy.x + random(-400, 400), y: enemy.y + random(-400, 400)}
              enemy.mode = :wandering
            end
          end

          if enemy.target
            if enemy.mode == :hunting
              path = Pathfinding.find_path(
                level[:pathfinding_graph],
                start: { x: (enemy.x / level.cell_size).floor, y: (enemy.y / level.cell_size).floor },
                goal: { x: (player.x / level.cell_size).floor, y: (player.y / level.cell_size).floor }
              )
              if path.length > 1
                next_cell = path[1]
                enemy.target = { x: (next_cell.x + 0.5) * level.cell_size, y: (next_cell.y + 0.5) * level.cell_size }
              else
                enemy.target = player
              end
            end

            enemy.angle = args.geometry.angle_to(enemy, enemy.target)
            enemy.x_vel, enemy.y_vel = vel_from_angle(enemy.angle, enemy.speed)
            dist_to_target = (enemy.x - enemy.target.x) ** 2 + (enemy.y - enemy.target.y) ** 2
            if dist_to_target > enemy.speed ** 2 || enemy.mode == :hunting
              enemy.x += enemy.x_vel
              enemy.y += enemy.y_vel
            else
              enemy.delay_counter = 0
              enemy.x = enemy.target.x
              enemy.y = enemy.target.y
              enemy.target = false
              enemy.mode = :idle
            end
          end
        end

        tick_flasher(enemy)

        enemy.merge!(RED) if enemy.health == 1 && enemy.max_health > 1

        screen = Camera.translate(args.state.camera, enemy)
        debug_label(args, screen.x, screen.y, "health: #{enemy.health}")
        debug_label(args, screen.x, screen.y - 14, "speed: #{enemy.mode}")
      end
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
  end
end
