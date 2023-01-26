module Scene
  MAXIMUM_ENEMIES = 80
  class << self
    def tick_gameplay(args)
      level = args.state.level
      player = args.state.player ||= Player.create(args, x: level[:start_position][:x], y: level[:start_position][:y])
      artifact = args.state.artifact ||= Artifact.create(args)
      cards = args.state.cards ||= Cards.create(args)
      camera = args.state.camera ||= Camera.build
      enemies = args.state.enemies ||= []
      args.state.enemies_destroyed ||= 0
      args.state.exp_chips ||= []
      enemy_spawn_timer = args.state.enemy_spawn_timer ||= Timer.every(60)

      if Input.window_out_of_focus?(args.inputs) || Input.pause?(args.inputs)
        play_sfx(args, :select)
        return Scene.switch(args, :paused, reset: true)
      end

      args.state.render_minimap = !args.state.render_minimap if Input.toggle_minimap?(args.inputs)

      # spawns enemies faster when player level is higher;
      # starts at every 60 ticks
      Timer.update_period(enemy_spawn_timer, [60 - 5 * player.level, 20].max)

      Timer.tick(enemy_spawn_timer)
      if Timer.active?(enemy_spawn_timer)
        if (enemies.length / MAXIMUM_ENEMIES) < rand
          Enemy.spawn(args)
        end
      end

      Cards.tick(args, cards, player)

      Player.tick(args, player, camera)
      enemies.each { |e| Enemy.tick(args, e, player, level)  }
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
          familiar.health -= 1
        end
      end

      Collision.detect(args.state.exp_chips, player) do |exp_chip, _|
        exp_chip.dead = true
        Player.absorb_exp(args, player, exp_chip)
        play_sfx(args, :exp_chip)
      end
	  
      Collision.detect(player, artifact) do |player, _|
        Player.level_up(args, player)
        args.state.artifact = nil
      end

      enemies.reject! { |e| e.dead }
      args.state.exp_chips.reject! { |e| e.dead }
      player.familiars.reject! { |e| e.dead }

      if player.dead?
        play_sfx(args, :player_death)
        return Scene.switch(args, :game_over)
      end
      if player.complete
        exterminate_sound(args, :magic)
        play_sfx(args, :level_up)
        return Scene.switch(args, :win)
      end

      Camera.follow(camera, target: player, bounds: level[:bounds])

      draw_bg(args, BLACK)
      Level.draw(args, level, camera: camera)
      args.outputs.sprites << [
        Camera.translate(camera, artifact),
        Camera.translate(camera, args.state.exp_chips),
        Camera.translate(camera, args.state.player.bullets),
        Camera.translate(camera, player),
        Camera.translate(camera, enemies),
        Camera.translate(camera, args.state.player.familiars)
      ]
      Minimap.draw(args, level: level, player: player, artifact: artifact, enemies: enemies) if args.state.render_minimap

      # draw the magic cards
      args.outputs.sprites << Cards.draw(cards, player)

      labels = []
      labels << label("#{text(:health)}: #{player.health}/#{player.max_health}", x: 40, y: args.grid.top - 40, size: SIZE_SM, font: FONT_BOLD)
      labels << label("#{text(:mana)}: #{player.mana}/#{player.max_mana}", x: 40, y: args.grid.top - 80, size: SIZE_SM, font: FONT_BOLD)
      # labels << label("Spell: #{player.spell + 1}", x: 40, y: args.grid.top - 120, size: SIZE_XS, font: FONT_BOLD)
      # labels << label("#{text(:level)}: #{player.level}", x: args.grid.right - 40, y: args.grid.top - 40, size: SIZE_SM, align: ALIGN_RIGHT, font: FONT_BOLD)
      # labels << label("#{text(:exp_to_next_level)}: #{player.exp_to_next_level}", x: args.grid.right - 40, y: args.grid.top - 88, size: SIZE_XS, align: ALIGN_RIGHT, font: FONT_BOLD)
      args.outputs.labels << labels
    end

    def reset_gameplay(args)
      args.state.camera = nil
      args.state.player = nil
      args.state.artifact = nil
      args.state.cards = nil
      args.state.enemies = nil
      args.state.enemies_destroyed = nil
      args.state.exp_chips = nil
    end
  end
end
