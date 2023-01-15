module Scene
  class << self
    def tick_gameplay(args)
      # creates the maze for the levels
      args.state.level ||= Level.new(mode: MODE[:small])
      # creates the starting point for the player
      args.state.start_position ||= {
          x: args.state.level.start_cell.x * args.state.level.size + (args.state.level.size / 2),
          y: args.state.level.start_cell.y * args.state.level.size + (args.state.level.size / 2)
      }
      args.state.player ||= Player.create(args)
      args.state.camera_viewport ||= { x: 0, y: 0, w: 1280, h: 720 }
      args.state.enemies ||= []
      args.state.enemies_destroyed ||= 0
      args.state.exp_chips ||= []

      camera = args.state.camera_viewport

      if !args.inputs.keyboard.has_focus || Input.pause?(args.inputs)
        play_sfx(args, :select)
        return Scene.switch(args, :paused, reset: true)
      end

      # spawns enemies faster when player level is higher;
      # starts at every 12 seconds
      if args.state.tick_count % FPS * (12 - (args.state.player.level  * 0.5).to_i) == 0
        Enemy.spawn(args, camera: camera)

        # double spawn at higher levels
        if args.state.player.level >= 12
          Enemy.spawn(args, camera: camera)
        end
      end


      Player.tick(args, args.state.player, camera)
      args.state.enemies.each { |e| Enemy.tick(args, e)  }
      args.state.exp_chips.each { |c| ExpChip.tick(args, c)  }

      collide(args.state.player.bullets, args.state.enemies) do |bullet, enemy|
        bullet.dead = true
        Enemy.damage(args, enemy, bullet)
      end

      collide(args.state.enemies, args.state.player) do |enemy, player|
        player.health -= enemy.body_power unless player.invincible
        flash(player, RED, 12)
        Enemy.damage(args, enemy, player, sfx: nil)
        play_sfx(args, :hurt)
      end

      collide(args.state.enemies, args.state.player.familiars) do |enemy, familiar|
        if familiar.cooldown_countdown <= 0
          Enemy.damage(args, enemy, familiar, sfx: :enemy_hit_by_familiar)
          familiar.cooldown_countdown = familiar.cooldown_ticks
        end
      end

      collide(args.state.exp_chips, args.state.player) do |exp_chip, player|
        exp_chip.dead = true
        Player.absorb_exp(args, player, exp_chip)
        play_sfx(args, :exp_chip)
      end

      args.state.enemies.reject! { |e| e.dead? }
      args.state.exp_chips.reject! { |e| e.dead }

      if args.state.player.dead?
        play_sfx(args, :player_death)
        return Scene.switch(args, :game_over)
      end

      update_camera_position(camera, player: args.state.player, level: args.state.level)

      draw_bg(args, BLACK)
      args.state.level.draw(args, camera)
      args.outputs.sprites << [
        translated(camera, args.state.exp_chips),
        translated(camera, args.state.player.bullets),
        translated(camera, args.state.player),
        translated(camera, args.state.enemies),
        translated(camera, args.state.player.familiars)
      ]

      labels = []
      labels << label("#{text(:health)}: #{args.state.player.health}", x: 40, y: args.grid.top - 40, size: SIZE_SM, font: FONT_BOLD)
      labels << label("#{text(:level)}: #{args.state.player.level}", x: args.grid.right - 40, y: args.grid.top - 40, size: SIZE_SM, align: ALIGN_RIGHT, font: FONT_BOLD)
      labels << label("#{text(:exp_to_next_level)}: #{args.state.player.exp_to_next_level}", x: args.grid.right - 40, y: args.grid.top - 88, size: SIZE_XS, align: ALIGN_RIGHT, font: FONT_BOLD)
      args.outputs.labels << labels
    end

    def update_camera_position(camera, player:, level:)
      bounds = level.bounds
      camera[:x] = (player.x - (camera.w / 2) + (player.w / 2)).clamp(0, bounds.right - camera.w)
      camera[:y] = (player.y - (camera.h / 2) + (player.h / 2)).clamp(0, bounds.top - camera.h)
    end

    def translated(camera, object)
      return object.map { |o| translated(camera, o) } if object.is_a?(Array)

      object.merge(
        x: object.x - camera.x,
        y: object.y - camera.y
      )
    end

    def reset_gameplay(args)
      args.state.player = nil
      args.state.enemies = nil
      args.state.enemies_destroyed = nil
      args.state.exp_chips = nil
    end
  end
end
