module Scene
  class << self
    def tick_gameplay(args)
      args.state.level ||= generate_level
      level = args.state.level
      args.state.player ||= Player.create(args, x: level[:start_position][:x], y: level[:start_position][:y])
      player = args.state.player
      args.state.camera ||= Camera.build
      camera = args.state.camera
      args.state.enemies ||= []
      args.state.enemies_destroyed ||= 0
      args.state.exp_chips ||= []
      args.state.enemy_spawn_timer ||= Timer.every(60)
      enemy_spawn_timer = args.state.enemy_spawn_timer

      if Input.window_out_of_focus?(args.inputs) || Input.pause?(args.inputs)
        play_sfx(args, :select)
        return Scene.switch(args, :paused, reset: true)
      end

      # spawns enemies faster when player level is higher;
      # starts at every 60 ticks
      Timer.update_period enemy_spawn_timer, 60 - (player.level * 2)

      Timer.tick(enemy_spawn_timer)
      if Timer.active?(enemy_spawn_timer)
        Enemy.spawn(args)

        # double spawn at higher levels
        Enemy.spawn(args) if player.level >= 12
      end

      Player.tick(args, player, camera)
      args.state.enemies.each { |e| Enemy.tick(args, e)  }
      args.state.exp_chips.each { |c| ExpChip.tick(args, c)  }

      collide(player.bullets, args.state.enemies) do |bullet, enemy|
        bullet.dead = true
        Enemy.damage(args, enemy, bullet)
      end

      collide(args.state.enemies, player) do |enemy, _|
        player.health -= enemy.body_power unless player.invincible
        flash(player, RED, 12)
        Enemy.damage(args, enemy, player, sfx: nil)
        play_sfx(args, :hurt)
      end

      collide(args.state.enemies, player.familiars) do |enemy, familiar|
        if familiar.cooldown_countdown <= 0
          Enemy.damage(args, enemy, familiar, sfx: :enemy_hit_by_familiar)
          familiar.cooldown_countdown = familiar.cooldown_ticks
        end
      end

      collide(args.state.exp_chips, player) do |exp_chip, _|
        exp_chip.dead = true
        Player.absorb_exp(args, player, exp_chip)
        play_sfx(args, :exp_chip)
      end

      args.state.enemies.reject! { |e| e.dead? }
      args.state.exp_chips.reject! { |e| e.dead }

      if player.dead?
        play_sfx(args, :player_death)
        return Scene.switch(args, :game_over)
      end

      Camera.follow(camera, target: player, bounds: level[:bounds])

      draw_bg(args, BLACK)
      draw_level(args, level: level, camera: camera)
      args.outputs.sprites << [
        Camera.translate(camera, args.state.exp_chips),
        Camera.translate(camera, args.state.player.bullets),
        Camera.translate(camera, player),
        Camera.translate(camera, args.state.enemies),
        Camera.translate(camera, args.state.player.familiars)
      ]

      labels = []
      labels << label("#{text(:health)}: #{player.health}", x: 40, y: args.grid.top - 40, size: SIZE_SM, font: FONT_BOLD)
      labels << label("#{text(:level)}: #{player.level}", x: args.grid.right - 40, y: args.grid.top - 40, size: SIZE_SM, align: ALIGN_RIGHT, font: FONT_BOLD)
      labels << label("#{text(:exp_to_next_level)}: #{player.exp_to_next_level}", x: args.grid.right - 40, y: args.grid.top - 88, size: SIZE_XS, align: ALIGN_RIGHT, font: FONT_BOLD)
      args.outputs.labels << labels
    end

    def generate_level
      cell_size = 256
      maze_size = 30
      grid = LevelGeneration::MazeGenerator.new(size: maze_size).generate
      start_cell = grid.flatten.reject(&:wall).sample
      {
        cell_size: cell_size,
        bounds: { x: 0, y: 0, w: maze_size * cell_size, h:  maze_size * cell_size },
        grid: grid,
        start_position: {
          x: (start_cell[:x] * cell_size) + (cell_size / 2) - (Player::W / 2),
          y: (start_cell[:y] * cell_size) + (cell_size / 2) - (Player::H / 2)
        }
      }
    end

    def draw_level(args, level:, camera:)
      cell_size = level[:cell_size]
      level[:grid].each do |row|
        row.each do |cell|
          next unless cell[:wall]

          rendered_cell = {
            x: (cell[:x] * cell_size),
            y: (cell[:y] * cell_size),
            w: cell_size,
            h: cell_size
          }
          next unless rendered_cell.intersect_rect? camera

          args.outputs.sprites << rendered_cell.sprite!(
            x: rendered_cell.x - camera.x,
            y: rendered_cell.y - camera.y,
            path: :pixel,
            r: 111, g: 111, b: 111
          )
        end
      end
    end

    def reset_gameplay(args)
      args.state.player = nil
      args.state.enemies = nil
      args.state.enemies_destroyed = nil
      args.state.exp_chips = nil
    end
  end
end
