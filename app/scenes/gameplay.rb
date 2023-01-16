module Scene
  class << self
    def tick_gameplay(args)
      # creates the maze for the levels
      args.state.level ||= Level.new(mode: MODE[:small])
      level = args.state.level
      args.state.player ||= Player.create(
        args,
        x: (level.start_cell.x * level.cell_size) + (level.cell_size / 2) - (Player::W / 2),
        y: (level.start_cell.y * level.cell_size) + (level.cell_size / 2) - (Player::H / 2)
      )
      player = args.state.player
      args.state.camera ||= Camera.build
      args.state.enemies ||= []
      args.state.enemies_destroyed ||= 0
      args.state.exp_chips ||= []

      camera = args.state.camera

      if !args.inputs.keyboard.has_focus || Input.pause?(args.inputs)
        play_sfx(args, :select)
        return Scene.switch(args, :paused, reset: true)
      end

      # spawns enemies faster when player level is higher;
      # starts at every 12 seconds
      if args.state.tick_count % FPS * (12 - (player.level  * 0.5).to_i) == 0
        Enemy.spawn(args, camera: camera)

        # double spawn at higher levels
        if player.level >= 12
          Enemy.spawn(args, camera: camera)
        end
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

      Camera.follow(camera, target: player, bounds: level.bounds)

      draw_bg(args, BLACK)
      level.draw(args, camera)
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

    def reset_gameplay(args)
      args.state.player = nil
      args.state.enemies = nil
      args.state.enemies_destroyed = nil
      args.state.exp_chips = nil
    end
  end
end
