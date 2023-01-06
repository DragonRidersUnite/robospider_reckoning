module Scene
  class << self
    def tick_gameplay(args)
      args.state.player ||= Player.create(args)
      args.state.enemies ||= []
      args.state.enemies_destroyed ||= 0
      args.state.exp_chips ||= []

      if !args.state.has_focus && args.inputs.keyboard.has_focus
        args.state.has_focus = true
      elsif args.state.has_focus && !args.inputs.keyboard.has_focus
        args.state.has_focus = false
      end

      if !args.state.has_focus || pause_down?(args)
        play_sfx(args, :select)
        return Scene.switch(args, :paused, reset: true)
      end

      # spawns enemies faster when player level is higher;
      # starts at every 12 seconds
      if args.state.tick_count % FPS * (12 - (args.state.player.level  * 0.5).to_i) == 0
        Enemy.spawn(args)

        # double spawn at higher levels
        if args.state.player.level >= 12
          Enemy.spawn(args)
        end
      end

      Player.tick(args, args.state.player)
      args.state.enemies.each { |e| Enemy.tick(args, e)  }
      args.state.exp_chips.each { |c| tick_exp_chip(args, c)  }
      collide(args, args.state.player.bullets, args.state.enemies, -> (args, bullet, enemy) do
        bullet.dead = true
        Enemy.damage(args, enemy, bullet)
      end)
      collide(args, args.state.enemies, args.state.player, -> (args, enemy, player) do
        player.health -= enemy.body_power unless player.invincible
        flash(player, RED, 12)
        Enemy.damage(args, enemy, player, sfx: nil)
        play_sfx(args, :hurt)
      end)
      collide(args, args.state.enemies, args.state.player.familiars, -> (args, enemy, familiar) do
        if familiar.cooldown_countdown <= 0
          Enemy.damage(args, enemy, familiar, sfx: :enemy_hit_by_familiar)
          familiar.cooldown_countdown = familiar.cooldown_ticks
        end
      end)
      collide(args, args.state.exp_chips, args.state.player, -> (args, exp_chip, player) do
        exp_chip.dead = true
        Player.absorb_exp(args, player, exp_chip)
        play_sfx(args, :exp_chip)
      end)
      args.state.enemies.reject! { |e| e.dead? }
      args.state.exp_chips.reject! { |e| e.dead }

      if args.state.player.dead?
        play_sfx(args, :player_death)
        return Scene.switch(args, :game_over)
      end

      draw_bg(args, BLACK)
      args.outputs.sprites << [args.state.exp_chips, args.state.player.bullets, args.state.player, args.state.enemies, args.state.player.familiars]

      labels = []
      labels << label("#{text(:health)}: #{args.state.player.health}", x: 40, y: args.grid.top - 40, size: SIZE_SM, font: FONT_BOLD)
      labels << label("#{text(:level)}: #{args.state.player.level}", x: args.grid.right - 40, y: args.grid.top - 40, size: SIZE_SM, align: ALIGN_RIGHT, font: FONT_BOLD)
      labels << label("#{text(:exp_to_next_level)}: #{args.state.player.exp_to_next_level}", x: args.grid.right - 40, y: args.grid.top - 88, size: SIZE_XS, align: ALIGN_RIGHT, font: FONT_BOLD)
      args.outputs.labels << labels
    end
  end
end
