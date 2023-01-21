module Player
  INIT_BULLET_DELAY = 10
  BULLET_SIZE = 10
  W = 32
  H = 32

  class << self
    # returns a new player data structure
    def create(args, x:, y:)
      p = {
        x: x,
        y: y,
        w: W,
        h: H,
        health: 6,
        max_health: 6,
        speed: 4,
        level: 1,
        path: Sprite.for(:player),
        exp_to_next_level: LEVEL_PROG[2][:exp_diff],
        bullets: [],
        familiars: [],
        exp_chip_magnetic_dist: 50,
        bullet_delay: INIT_BULLET_DELAY,
        bullet_delay_counter: INIT_BULLET_DELAY,
        body_power: 10,
        fire_pattern: FP_SINGLE,
        direction: DIR_UP,
        invincible: false,
      }.merge(WHITE)

      p.define_singleton_method(:dead?) do
        health <= 0
      end

      p
    end

    def tick(args, player, camera)
      firing = Input.fire?(args.inputs)

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
          bullets << bullet(player, add_to_angle(player.angle, -15))
          bullets << bullet(player, add_to_angle(player.angle, 15))
        when FP_QUAD
          bullets << bullet(player, player.angle)
          bullets << bullet(player, opposite_angle(player.angle))
          bullets << bullet(player, add_to_angle(player.angle, -15))
          bullets << bullet(player, add_to_angle(player.angle, 15))
        end

        play_sfx(args, :shoot)
        player.bullet_delay_counter = 0
        player.bullets.concat(bullets)
      end

      player.bullets.each do |b|
        x_vel, y_vel = vel_from_angle(b.angle, b.speed)
        b.x += x_vel
        b.y += y_vel

        if out_of_bounds?(camera, b)
          b.dead = true
        end
      end

      player.bullets.reject! { |b| b.dead }

      player.familiars.each { |f| Familiar.tick(args, player, f) }

      tick_flasher(player)

      if player.health == 1
        player.merge!(RED)
      end

      position_on_screen = Camera.translate(args.state.camera, player)
      debug_label(args, position_on_screen.x, position_on_screen.y, "dir: #{player.direction}")
      debug_label(args, position_on_screen.x, position_on_screen.y - 14, "angle: #{player.angle}")
      debug_label(args, position_on_screen.x, position_on_screen.y - 28, "bullets: #{player.bullets.length}")
      debug_label(args, position_on_screen.x, position_on_screen.y - 42, "exp 2 nxt lvl: #{player.exp_to_next_level}")
      debug_label(args, position_on_screen.x, position_on_screen.y - 54, "bullet delay: #{player.bullet_delay}")
    end

    def bullet(player, angle)
      {
        x: player.x + player.w / 2 - BULLET_SIZE / 2,
        y: player.y + player.h / 2 - BULLET_SIZE / 2,
        w: BULLET_SIZE,
        h: BULLET_SIZE,
        angle: angle,
        speed: 12,
        power: 1,
        dead: false,
        path: Sprite.for(:bullet),
      }.merge(WHITE)
    end

    def absorb_exp(args, player, exp_chip)
      player.exp_to_next_level -= exp_chip.exp_amount

      # level up every 10 points
      if (player.exp_to_next_level <= 0)
        level_up(args, player)
      end
    end

    def level_up(args, player)
      player.level += 1
      level_up = LEVEL_PROG[player.level] || { exp_diff: 100, on_reach: -> (_, _) {} } # just weird fallback
      player.exp_to_next_level = level_up[:exp_diff]
      play_sfx(args, :level_up)
      level_up[:on_reach].call(args, player)

      if player.level >= 10
        Enemy.spawn(args, :king)
      end
    end
  end

  LEVEL_PROG = {
    2 => {
      exp_diff: 10,
      on_reach: -> (args, player) do
        Familiar.spawn(player, dist_from_player: 66)
        args.gtk.notify!(text(:lu_familiar_spawned))
      end
    },
    3 => {
      exp_diff: 20,
      on_reach: -> (args, player) do
        player.familiars.each do |f|
          f.speed += 3
        end
        args.gtk.notify!(text(:lu_familiar_speed_increased))
      end
    },
    4 => {
      exp_diff: 22,
      on_reach: -> (args, player) do
        player.fire_pattern = FP_DUAL
        args.gtk.notify!(text(:lu_fp_dual_shot))
      end
    },
    5 => {
      exp_diff: 25,
      on_reach: -> (args, player) do
        familiar = Familiar.spawn(player, dist_from_player: 100)
        args.gtk.notify!(text(:lu_familiar_spawned))
        familiar.speed = player.familiars.first.speed + 2
      end
    },
    6 => {
      exp_diff: 26,
      on_reach: -> (args, player) do
        player.exp_chip_magnetic_dist *= 2
        args.gtk.notify!(text(:lu_player_exp_magnetism_increased))
      end
    },
    7 => {
      exp_diff: 30,
      on_reach: -> (args, player) do
        player.speed += 2
        args.gtk.notify!(text(:lu_player_speed_increased))
      end
    },
    8 => {
      exp_diff: 33,
      on_reach: -> (args, player) do
        player.fire_pattern = FP_TRI
        args.gtk.notify!(text(:lu_fp_tri_shot))
      end
    },
    9 => {
      exp_diff: 35,
      on_reach: -> (args, player) do
        player.bullet_delay -= 2
        args.gtk.notify!(text(:lu_player_fire_rate_increased))
      end
    },
    10 => {
      exp_diff: 38,
      on_reach: -> (args, player) do
        player.fire_pattern = FP_QUAD
        args.gtk.notify!(text(:lu_fp_quad_shot))
      end
    },
  }
end
