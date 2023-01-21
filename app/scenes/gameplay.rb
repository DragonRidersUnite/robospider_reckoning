module Scene
  class << self
    def tick_gameplay(args)
      level = args.state.level
      args.state.player ||= Player.create(args, x: level[:start_position][:x], y: level[:start_position][:y])
      player = args.state.player
      args.state.camera ||= Camera.build
      camera = args.state.camera
      args.state.enemies ||= []
      enemies = args.state.enemies
      args.state.enemies_destroyed ||= 0
      args.state.exp_chips ||= []
      args.state.enemy_spawn_timer ||= Timer.every(60)
      enemy_spawn_timer = args.state.enemy_spawn_timer

      if Input.window_out_of_focus?(args.inputs) || Input.pause?(args.inputs)
        play_sfx(args, :select)
        return Scene.switch(args, :paused, reset: true)
      end

      args.state.render_minimap = !args.state.render_minimap if Input.toggle_minimap?(args.inputs)

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
      enemies.each { |e| Enemy.tick(args, e)  }
      args.state.exp_chips.each { |c| ExpChip.tick(args, c)  }

      # TODO: Use some kind of spatial hash (quadtree?) to speed this up?
      Collision.detect(player, level[:walls]) do |player, wall|
        Collision.move_out_of_collider(player, wall)
      end

      Collision.detect(player.bullets, level[:walls]) do |bullet, _|
        bullet.dead = true
      end

      unless args.state.enemies_pass_walls
        Collision.detect(level[:walls], enemies) do |wall, enemy|
          Collision.move_out_of_collider(enemy, wall)
        end
      end

      Collision.detect(player.bullets, enemies) do |bullet, enemy|
        bullet.dead = true
        Enemy.damage(args, enemy, bullet)
      end

      Collision.detect(enemies, player) do |enemy, _|
        player.health -= enemy.body_power unless player.invincible
        flash(player, RED, 12)
        Enemy.damage(args, enemy, player, sfx: nil)
        play_sfx(args, :hurt)
      end

      Collision.detect(enemies, player.familiars) do |enemy, familiar|
        if familiar.cooldown_countdown <= 0
          Enemy.damage(args, enemy, familiar, sfx: :enemy_hit_by_familiar)
          familiar.cooldown_countdown = familiar.cooldown_ticks
        end
      end

      Collision.detect(args.state.exp_chips, player) do |exp_chip, _|
        exp_chip.dead = true
        Player.absorb_exp(args, player, exp_chip)
        play_sfx(args, :exp_chip)
      end

      enemies.reject! { |e| e.dead }
      args.state.exp_chips.reject! { |e| e.dead }

      if player.dead?
        play_sfx(args, :player_death)
        return Scene.switch(args, :game_over)
      end

      Camera.follow(camera, target: player, bounds: level[:bounds])

      draw_bg(args, BLACK)
      Level.draw(args, level, camera: camera)
      args.outputs.sprites << [
        Camera.translate(camera, args.state.exp_chips),
        Camera.translate(camera, args.state.player.bullets),
        Camera.translate(camera, player),
        Camera.translate(camera, enemies),
        Camera.translate(camera, args.state.player.familiars)
      ]
      Minimap.draw(args, level: level, player: player, enemies: enemies) if args.state.render_minimap

      labels = []
      labels << label("#{text(:health)}: #{player.health}", x: 40, y: args.grid.top - 40, size: SIZE_SM, font: FONT_BOLD)
      labels << label("#{text(:level)}: #{player.level}", x: args.grid.right - 40, y: args.grid.top - 40, size: SIZE_SM, align: ALIGN_RIGHT, font: FONT_BOLD)
      labels << label("#{text(:exp_to_next_level)}: #{player.exp_to_next_level}", x: args.grid.right - 40, y: args.grid.top - 88, size: SIZE_XS, align: ALIGN_RIGHT, font: FONT_BOLD)
      args.outputs.labels << labels
    end

    def reset_gameplay(args)
      args.state.camera = nil
      args.state.player = nil
      args.state.enemies = nil
      args.state.enemies_destroyed = nil
      args.state.exp_chips = nil
    end
  end
end
