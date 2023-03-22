module Player
  BULLET_SIZE = 10
  BULLET_LIFE = 15
  W = 32
  H = 32

  class << self
    # returns a new player data structure
    def create(args, x:, y:)
      legged_creature = LeggedCreature.create(args, x: x, y: y)
      p = {
        x: x,
        y: y,
        w: W,
        h: H,
        health: Difficulty.based(args, [12, 6, 4]),
        max_health: Difficulty.based(args, [12, 6, 4]),
        speed: Difficulty.based(args, [3, 2, 1]),
        level: 1,
        path: Sprite.for(:player),
        mana: 10,
        max_mana: 20,
        spell: 0,
        spell_count: 1,
        spell_cost: [1, 5, 10, 10, 100],
        spell_delay: [20, 30, 60, 30, 180],
        spell_delay_counter: 0,
        bullets: [],
        bullet_offset: 30,
        firing: false,
        fire_pattern: FP_SINGLE,
        familiars: [],
        familiar_limit: 0,
        familiar_speed: 1.5,
        familiar_angle: 0,
        rushing: false,
        rush_mana_cost: 0.05,
        mana_chip_magnetic_dist: 50,
        bullet_lifetime: BULLET_LIFE,
        body_power: 10,
        direction: DIR_UP,
        invincible: false,
        xp: 0,
        xp_needed: 20,
        key_found: false,
        contemplating: 0,
        contemplation: 120,
        mana_regen: false,
        mana_rate: 250,
        effects: []
      }.merge(WHITE).merge(legged_creature)

      p.define_singleton_method(:rush_speed) do
        speed * 2
      end

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

      if Input.rush?(args.inputs) && player.mana > player.rush_mana_cost
        player.mana -= player.rush_mana_cost
        player.rushing = true

        lin_vel = vel_from_angle(player.angle + 180, player.rush_speed)
      else
        player.rushing = false

        lin_vel = [player.speed * move.x, player.speed * move.y]
      end

      # Player position/movement is handled here
      LeggedCreature.update(args, player, lin_vel, firing, player.rushing)
      # player.angle = angle_for_dir(player.direction)

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
        b.life -= 1

        if b.life <= 0 || b.dead
          b.dead = true
          if b.bomb
            b.bullet_lifetime = 600
            i = -1
            while (i += 1) < 36
              temp << bullet(b, 10 * i)
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
      elsif !player.flashing
        reset_color(player)
      end
      # tick for effects
      player.effects.reject! { ParticleSystem.dead? _1 }
      player.effects.each { ParticleSystem.tick(args, _1) }

      player.mana += 1 if player.mana_regen && args.tick_count.mod_zero?(player.mana_rate)

      debug_block do
        position_on_screen = Camera.translate(args.state.camera, player)
        x,y = *muzzle_position(player)
        muzzle = Camera.translate(args.state.camera, {x: x, y: y})
        debug_border(args, position_on_screen.x, position_on_screen.y, player.w, player.h, WHITE)
        debug_border(args, muzzle.x, muzzle.y, 5, 5, WHITE)
        ["x: #{player.x.to_sf}",
          "y: #{player.y.to_sf}",
          "dir: #{player.direction}",
          "angle: #{player.angle.to_sf}",
          "turret angle: #{player.turret_th}",
          "bullets: #{player.bullets.length}",
          "bullet delay: #{player.bullet_delay}",
          "effects #: #{player.effects.size}",
          "muzzle: #{muzzle_position(player)}"
        ].each_with_index do |text, i|
          debug_label(args, position_on_screen.x, position_on_screen.y - 20 * i, text)
        end
      end
    end

    def bullet(source, angle)
      x, y = *if source.bomb
                [source.x + source.w / 2, source.y + source.h / 2]
              else
                muzzle_position(source)
              end

      {
        x: x - BULLET_SIZE / 2,
        y: y - BULLET_SIZE / 2,
        w: BULLET_SIZE,
        h: BULLET_SIZE,
        angle: angle,
        speed: 12,
        power: 1,
        life: source.bullet_lifetime,
        bomb: false,
        dead: false,
        path: Sprite.for(:bullet)
      }.merge(WHITE)
    end

    def muzzle_position(player)
      [
        player.x + player.w / 2 + Math.cos(player.turret_th) * player.bullet_offset,
        player.y + player.h / 2 + Math.sin(player.turret_th) * player.bullet_offset
      ]
    end


    def bomb(player, angle)
      x, y = * muzzle_position(player)
      {
        x: x - BULLET_SIZE / 2,
        y: y - BULLET_SIZE / 2,
        w: BULLET_SIZE,
        h: BULLET_SIZE,
        angle: angle,
        speed: 0,
        power: 5,
        life: 300,
        bomb: true,
        dead: false,
        path: Sprite.for(:bomb)
      }.merge(WHITE)
    end

    def absorb_mana(args, player, mana_chip)
      player.mana = min(player.mana + mana_chip.exp_amount, player.max_mana)
    end

    def level_up(args, player)
      player.level += 1
      play_sfx(args, :level_up)
      new_level = LEVEL_PROG[player.level] || LEVEL_PROG[:default]
      new_level[:on_reach].call(args, player)
      player.mana_rate = (player.mana_rate - 10).clamp(30) if player.mana_regen
      Enemy.spawn(args, :king)
    end

    def enemy_knockback(args, player, enemy)
      knockback(args, player, enemy.body_power, enemy.speed, enemy.angle)
    end

    def knockback(args, player, strength, angle, speed)
      push = (strength + speed * 2).clamp(5, 20)
      push /= 2 if player.invincible
      vel_x, vel_y = vel_from_angle(angle, push)
      player.body_shift_x += vel_x
      player.body_shift_y += vel_y
    end
  end

  SPELLCAST = {
    0 => ->(args, player, firing) do # fire bullet
      player.spell_delay_counter += 1
      return unless firing && player.mana >= player.spell_cost[0]

      turret_angle = player.turret_th * 180 / Math::PI

      if player.spell_delay_counter >= player.spell_delay[0]
        bullets = []
        case player.fire_pattern
        when FP_SINGLE
          bullets << bullet(player, turret_angle)
        when FP_TRI
          bullets << bullet(player, turret_angle)
          bullets << bullet(player, add_to_angle(turret_angle, -10))
          bullets << bullet(player, add_to_angle(turret_angle, 10))
        end

        player.mana -= player.spell_cost[0]

        play_sfx(args, :shoot)
        player.bullets.concat(bullets)
        player.spell_delay_counter = 0
        Cards.mock_reload(args.state.cards, player)

        Player.knockback(args, player, player.body_power, (180 + turret_angle), 2)
        
        muzzle_position = muzzle_position(player)
        smoke = ParticleSystem.create(
          SmokeEffect,
          x: muzzle_position.x,
          y: muzzle_position.y,
          dir: turret_angle,
          w: 0,
          h: 0,
          rate: random(30, 50),
          duration: random(13, 22)
        )

        player.effects << smoke
      end
    end,
    1 => ->(args, player, firing) do # spawn familiar
      if firing && player.mana >= player.spell_cost[1] && player.familiars.length < player.familiar_limit
        player.spell_delay_counter += 1
        if player.spell_delay_counter >= player.spell_delay[1]
          play_sfx(args, :level_up)
          Familiar.spawn(player)
          player.mana -= player.spell_cost[1]
          player.spell_delay_counter = 0
          Cards.mock_reload(args.state.cards, player)
        end
      else
        player.spell_delay_counter = 0
      end
    end,
    2 => ->(args, player, firing) do # heal damage
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
    3 => ->(args, player, firing) do # spawn bomb
      player.spell_delay_counter += 1
      return unless firing && player.mana >= player.spell_cost[3]

      if player.spell_delay_counter >= player.spell_delay[3]
        player.mana -= player.spell_cost[3]
        play_sfx(args, :shoot)
        player.bullets << bomb(player, player.turret_th * 180 / Math::PI)
        player.spell_delay_counter = 0
        Cards.mock_reload(args.state.cards, player)
      end
    end,
    4 => ->(args, player, firing) do # joker card
      unless firing && player.mana >= player.spell_cost[4]
        player.spell_delay_counter = 0
        return
      end
      player.spell_delay_counter += 1

      if player.spell_delay_counter >= player.spell_delay[4]
        player.mana -= player.spell_cost[4]
        player.complete = true
        player.spell_delay_counter = 0
        Cards.mock_reload(args.state.cards, player)
      end
    end
  }

  LEVEL_PROG = {
    2 => {
      on_reach: ->(args, player) do
        player.max_mana += 10
        player.spell_count = 2
        player.familiar_limit = 3
        player.xp_needed *= 2
        player.rush_mana_cost -= 0.01
        player.mana_regen = true
      end
    },
    3 => {
      on_reach: ->(args, player) do
        player.mana_chip_magnetic_dist *= 2
        player.health += 4
        player.max_health += 4
        player.max_mana += 10
        player.spell_count = 3
        player.bullet_lifetime += 10
        player.familiar_limit += 1
        player.xp_needed *= 2
        player.rush_mana_cost -= 0.01
      end
    },
    4 => {
      on_reach: ->(args, player) do
        player.fire_pattern = FP_TRI
        player.speed += 1
        player.max_mana += 10
        player.spell_count = 3
        player.familiar_limit += 1
        player.familiar_speed += 3
        player.xp_needed *= 2
        player.rush_mana_cost -= 0.01
      end
    },
    5 => {
      on_reach: ->(args, player) do
        player.health += 10
        player.max_health += 10
        player.max_mana += 10
        player.spell_count = 4
        player.spell_delay[0] -= 5
        player.familiar_limit += 1
        player.xp_needed *= 2
        player.rush_mana_cost -= 0.005
      end
    },
    8 => {
      on_reach: ->(args, player) do
        player.health = 30
        player.max_health = 30
        player.max_mana = 100
        player.familiar_limit = 12
        player.spell_count = 5
        player.xp_needed *= 3
        player.rush_mana_cost -= 0.005
      end
    },
    :default => {
      on_reach: ->(args, player) do
        player.health += 2
        player.max_health += 2
        player.max_mana += 5
        player.familiar_limit += 1
        player.xp_needed *= 2
      end
    } # post-game rewards for collecting further artifacts
  }
end
