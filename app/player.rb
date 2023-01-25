module Player
  BULLET_SIZE = 10
  BULLET_LIFE = 10
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
        mana: 10,
        max_mana: 20,
        spell: 0,
        spell_count: 1,
        spell_cost: [1, 5, 10, 50],
        spell_delay: [20, 30, 60, 30],
        spell_delay_counter: 0,
        bullets: [],
        fire_pattern: FP_SINGLE,
        familiars: [],
        familiar_limit: 0,
        familiar_speed: 1,
        familiar_angle: 0,
        exp_chip_magnetic_dist: 50,
        bullet_lifetime: BULLET_LIFE,
        body_power: 10,
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

      move = Input.movement?(args.inputs)

      unless firing
        if move.x == -1
            player.direction = DIR_LEFT
        elsif move.x == 1
            player.direction = DIR_RIGHT
        elsif move.y == -1
            player.direction = DIR_DOWN
        elsif move.y == 1
            player.direction = DIR_UP
        end
      end

      player.x += player.speed * move.x
      player.y += player.speed * move.y

      player.angle = angle_for_dir(player.direction)

      if (move = Input.secondary_navigation?(args.inputs)) != 0
        player.spell = (player.spell + move) % player.spell_count
        player.spell_delay_counter = 0
      end

      SPELLCAST[player.spell].call(args, player, firing)

      player.bullets.each do |b|
        x_vel, y_vel = vel_from_angle(b.angle, b.speed)
        b.x += x_vel
        b.y += y_vel

        b.life -= 1
        if out_of_bounds?(camera, b) || b.life <= 0
          b.dead = true
        end
      end

      player.bullets.reject! { |b| b.dead }

      player.familiar_angle = (player.familiar_angle + player.familiar_speed) % 360
      player.familiars.each_with_index { |f, i| Familiar.tick(args, player, f, i) }

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
        life: player.bullet_lifetime,
        dead: false,
        path: Sprite.for(:bullet),
      }.merge(WHITE)
    end

    def absorb_exp(args, player, exp_chip)
      player.mana = [player.mana + exp_chip.exp_amount, player.max_mana].min
    end

    def level_up(args, player)
      player.level += 1
      level_up = LEVEL_PROG[player.level] || { exp_diff: 100, on_reach: -> (_, _) {} } # just weird fallback
      play_sfx(args, :level_up)
      level_up[:on_reach].call(args, player)

      if player.level >= 10
        Enemy.spawn(args, :king)
      end
    end
  end

  SPELLCAST = {
    0 => -> (args, player, firing) do # fire bullet
      player.spell_delay_counter += 1
      return unless (firing && player.mana >= player.spell_cost[0])

      if player.spell_delay_counter >= player.spell_delay[0]
        bullets = []
        case player.fire_pattern
        when FP_SINGLE
          bullets << bullet(player, player.angle)
        when FP_TRI
          bullets << bullet(player, player.angle)
          bullets << bullet(player, add_to_angle(player.angle, -15))
          bullets << bullet(player, add_to_angle(player.angle, 15))
        end

        player.mana -= player.spell_cost[0]

        play_sfx(args, :shoot)
        player.spell_delay_counter = 0
        player.bullets.concat(bullets)
      end
    end,
    1 => -> (args, player, firing) do # spawn familiar
      return unless firing && player.mana >= player.spell_cost[1]
      return if player.familiars.length >= player.familiar_limit
      player.spell_delay_counter += 1
      if player.spell_delay_counter >= player.spell_delay[1]
        play_sfx(args, :level_up)
        Familiar.spawn(player)
        player.mana -= player.spell_cost[1]
        player.spell_delay_counter = 0
      end
    end,
    2 => -> (args, player, firing) do # heal damage
      if firing && player.health < player.max_health && player.mana >= player.spell_cost[2]
        player.spell_delay_counter += 1

        if player.spell_delay_counter >= player.spell_delay[2]
          play_sfx(args, :level_up)
          player.mana -= player.spell_cost[2]
          player.health = [player.health + 1, player.max_health].min
          player.spell_delay_counter = 0
        end
      else
        player.spell_delay_counter = 0
      end
    end,
    3 => -> (args, player, firing) do # spawn bomb?
  
    end,
    
  }

  LEVEL_PROG = {
    2 => {
      exp_diff: 10,
      on_reach: -> (args, player) do
        player.max_mana += 10
        player.spell_count = 2
        player.familiar_limit = 3
      end
    },
    3 => {
      exp_diff: 20,
      on_reach: -> (args, player) do
        player.health += 4
        player.max_health += 4
        player.max_mana += 10
        player.familiar_speed += 3
        player.familiar_limit += 1
        player.spell_count = 3
      end
    },
    4 => {
      exp_diff: 22,
      on_reach: -> (args, player) do
        player.health += 5
        player.max_health += 5
        player.max_mana += 10
        player.spell_count = 3
        player.bullet_lifetime += 10
        player.familiar_limit += 1
      end
    },
    5 => {
      exp_diff: 25,
      on_reach: -> (args, player) do
        player.health += 5
        player.max_health += 5
        player.max_mana += 10
        player.spell_count = 4
        player.familiar_limit += 1
      end
    },






    6 => {
      exp_diff: 26,
      on_reach: -> (args, player) do
        player.exp_chip_magnetic_dist *= 2
        player.familiar_limit += 1
      end
    },
    7 => {
      exp_diff: 30,
      on_reach: -> (args, player) do
        player.speed += 2
        player.familiar_limit += 1
        args.gtk.notify!(text(:lu_player_speed_increased))
      end
    },
    8 => {
      exp_diff: 33,
      on_reach: -> (args, player) do
        player.fire_pattern = FP_TRI
        player.familiar_limit += 1
        args.gtk.notify!(text(:lu_fp_tri_shot))
      end
    },
    9 => {
      exp_diff: 35,
      on_reach: -> (args, player) do
        player.spell_delay[0] -= 5
        player.familiar_limit += 1
        args.gtk.notify!(text(:lu_player_fire_rate_increased))
      end
    },
    10 => {
      exp_diff: 38,
      on_reach: -> (args, player) do
        player.familiar_limit += 1
      end
    },
  }
end
