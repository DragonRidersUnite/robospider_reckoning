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
        spell_cost: [1, 5, 10, 10],
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
      firing = player.firing = Input.fire?(args.inputs)

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

      # tick for bullets
	  temp = []
      player.bullets.each do |b|
        x_vel, y_vel = vel_from_angle(b.angle, b.speed)
        b.x += x_vel
        b.y += y_vel

        putz b

        b.life -= 1
        if b.life <= 0 || b.dead
          b.dead = true
          if b.bomb
            bullets = []
			i = 0
            b.bullet_lifetime = 600
			while i < 36
              temp << bullet(b, 10 * i, false)
              i += 1
            end
          end
        end
      end
      player.bullets.concat(temp) 

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

    def bullet(player, angle, bomb = false)
      if bomb
      {
        x: player.x + player.w / 2 - 10 / 2,
        y: player.y + player.h / 2 - 10 / 2,
        w: 20,
        h: 20,
        angle: angle,
        speed: 0,
        power: 10,
        life: 1200,
		bomb: bomb,
        dead: false,
        path: Sprite.for(bomb ? :bomb : :bullet),
      }.merge(WHITE)
      else
      {
        x: player.x + player.w / 2 - BULLET_SIZE / 2,
        y: player.y + player.h / 2 - BULLET_SIZE / 2,
        w: BULLET_SIZE,
        h: BULLET_SIZE,
        angle: angle,
        speed: 12,
        power: 1,
        life: player.bullet_lifetime,
		bomb: bomb,
        dead: false,
        path: Sprite.for(:bullet),
      }.merge(WHITE)
      end
    end

    def absorb_exp(args, player, exp_chip)
      player.mana = [player.mana + exp_chip.exp_amount, player.max_mana].min
    end

    def level_up(args, player)
      player.level += 1
      level_up = LEVEL_PROG[player.level] || {on_reach: -> (args, player) { 
        player.health += 2
        player.max_health += 2
        player.max_mana += 5
        player.familiar_limit += 1} } # post-game rewards for collecting further artifacts
      play_sfx(args, :level_up)
      level_up[:on_reach].call(args, player)
      Enemy.spawn(args, :king)
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
          bullets << bullet(player, add_to_angle(player.angle, -10))
          bullets << bullet(player, add_to_angle(player.angle, 10))
        end

        player.mana -= player.spell_cost[0]

        play_sfx(args, :shoot)
        player.bullets.concat(bullets)
        player.spell_delay_counter = 0
        Cards.mock_reload(args.state.cards, player)
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
        Cards.mock_reload(args.state.cards, player)
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
          Cards.mock_reload(args.state.cards, player)
        end
      else
        player.spell_delay_counter = 0
      end
    end,
    3 => -> (args, player, firing) do # spawn bomb?
      player.spell_delay_counter += 1
      return unless (firing && player.mana >= player.spell_cost[3])

      if player.spell_delay_counter >= player.spell_delay[3]
        player.mana -= player.spell_cost[3]
        play_sfx(args, :shoot)
        player.bullets << bullet(player, player.angle, true)
        player.spell_delay_counter = 0
        Cards.mock_reload(args.state.cards, player)
      end
    end,
  }

  LEVEL_PROG = {
    2 => {
      on_reach: -> (args, player) do
        player.max_mana += 10
        player.spell_count = 2
        player.familiar_limit = 3
      end
    },
    3 => {
      on_reach: -> (args, player) do
        player.exp_chip_magnetic_dist *= 2
        player.health += 4
        player.max_health += 4
        player.max_mana += 10
        player.spell_count = 3
        player.bullet_lifetime += 10
        player.familiar_limit += 1
      end
    },
    4 => {
      on_reach: -> (args, player) do
        player.fire_pattern = FP_TRI
        player.speed += 1
        player.max_mana += 10
        player.spell_count = 3
        player.familiar_limit += 1
        player.familiar_speed += 3
      end
    },
    5 => {
      on_reach: -> (args, player) do
        player.health += 10
        player.max_health += 10
        player.max_mana += 10
        player.spell_count = 4
        player.spell_delay[0] -= 5
        player.familiar_limit += 1
      end
    },
  }
end
