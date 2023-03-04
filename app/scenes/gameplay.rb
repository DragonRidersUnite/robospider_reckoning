module Scene
  MAXIMUM_ENEMIES = 80
  class << self
    def tick_gameplay(args)
      level = args.state.level
      player = args.state.player ||= Player.create(args, x: level[:start_position][:x], y: level[:start_position][:y])
      key = args.state.key ||= Artifact.create(args, :key)
      door = args.state.door ||= Artifact.create(args, :door)
      cards = args.state.cards ||= Cards.create(args)
      camera = args.state.camera ||= Camera.build
      enemies = args.state.enemies ||= []
      boss = args.state.boss ||= {}
      boss = Boss.create(args, player) if boss.empty? && args.state.current_level == Level::BOSS_LEVEL
      args.state.enemies_destroyed ||= 0
      args.state.mana_chips ||= []
      enemy_spawn_timer = args.state.enemy_spawn_timer ||= Timer.every(60)

      if Input.window_out_of_focus?(args.inputs) || Input.pause?(args.inputs)
        play_sfx(args, :select)
        return Scene.switch(args, :paused, reset: true)
      end

      Timer.update_period(enemy_spawn_timer, 60)

      Timer.tick(enemy_spawn_timer)
      if Timer.active?(enemy_spawn_timer)
        if (enemies.length / MAXIMUM_ENEMIES) < rand
          Enemy.spawn(args)
        end
      end

      Cards.tick(args, cards, player)

      Player.tick(args, player, camera)

      enemies.each { |e| Enemy.tick(args, e, player, level)  }
      args.state.mana_chips.each { |c| ManaChip.tick(args, c)  }

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
        player.xp += enemy.xp if enemy.dead
      end

      Collision.detect(enemies, player) do |enemy, _|
        player.health -= [enemy.body_power, enemy.health].min unless player.invincible
        Player.knockback(args, player, enemy)
        flash(player, RED, 12)
        Enemy.damage(args, enemy, player, sfx: nil)
        play_sfx(args, :hurt)
        player.xp += enemy.xp if enemy.dead
      end

      Collision.detect(enemies, player.familiars) do |enemy, familiar|
        if familiar.cooldown_countdown <= 0
          Enemy.damage(args, enemy, familiar, sfx: :enemy_hit_by_familiar)
          player.xp += enemy.xp if enemy.dead
          familiar.cooldown_countdown = familiar.cooldown_ticks
          familiar.health -= 1
        end
      end

      Collision.detect(args.state.mana_chips, player) do |mana_chip, _|
        mana_chip.dead = true
        Player.absorb_mana(args, player, mana_chip)
        play_sfx(args, :mana_chip)
      end

      Collision.detect(player, key) { |player, _| open_door(args, player) } unless player.key_found
      Collision.detect(player, door.merge(y: door.y - 2)) { |player, _| return next_map(args, player) } if player.key_found

      enemies.reject!(&:dead)
      args.state.mana_chips.reject!(&:dead)
      player.familiars.reject!(&:dead)

      if !boss.empty?
        Boss.tick(args, boss, boss, player)

        unless boss.pass_walls
          Collision.detect(level[:walls], boss) do |wall, b|
            Collision.move_out_of_collider(b, wall)
          end
        end

        Collision.detect(player.bullets, boss) do |bullet, b|
          bullet.dead = true
          Boss.damage(args, b, bullet)
          player.xp += b.xp if b.dead
        end

        Collision.detect(boss, player) do |b, _|
          player.health -= [b.body_power, b.health].min unless player.invincible
          Player.knockback(args, player, b)
          flash(player, RED, 12)
          Boss.damage(args, b, player, sfx: nil)
          play_sfx(args, :hurt)
          player.xp += b.xp if b.dead
        end

        Collision.detect(enemies, boss) do |enemy, b|
          Boss.drain_life(boss, enemy)
          flash(boss[:sprite], MINI_GREEN, 6)
          Enemy.damage(args, enemy, boss, sfx: nil)
        end

        Collision.detect(boss, player.familiars) do |b, familiar|
          if familiar.cooldown_countdown <= 0
            Boss.damage(args, b, familiar, sfx: :enemy_hit_by_familiar)
            player.xp += b.xp if b.dead
            familiar.cooldown_countdown = familiar.cooldown_ticks
            familiar.health -= 2
          end
        end

        Collision.detect(args.state.mana_chips, boss) do |mana_chip, boss|
          mana_chip.dead = true
          Boss.absorb_mana(args, boss, mana_chip)
          #play_sfx(args, :mana_chip)
        end

      end

      Player.level_up(args, player) if player.xp >= player.xp_needed

      if player.dead?
        exterminate_sounds(args)
        play_sfx(args, :player_death)
        player.contemplating = player.contemplation
        return Scene.switch(args, :game_over)
      end

      if player.complete
        exterminate_sounds(args)
        play_sfx(args, :level_up)
        return Scene.switch(args, :win)
      end

      Camera.follow(camera, target: player, bounds: level[:bounds])

      draw_bg(args, BLACK)
      Level.draw(args, level, camera)
      args.outputs.sprites << [
        Camera.translate(camera, args.state.mana_chips),
        Camera.translate(camera, args.state.player.bullets),
        Camera.translate(camera, enemies),
        Camera.translate(camera, args.state.player.familiars),
        Camera.translate(camera, door)
      ]
      args.outputs.sprites << Camera.translate(camera, boss) if !boss.empty?
      args.outputs.sprites << Camera.translate(camera, key) unless player.key_found
      LeggedCreature.render(args, player, camera)

      Hud.tick(args)
      Hud.draw(args, player, level, key, door, enemies, cards)
    end

    def reset_gameplay(args)
      if args.state.next_level
        args.state.player.x = args.state.level[:start_position][:x]
        args.state.player.y = args.state.level[:start_position][:y]
      else
        args.state.camera = nil
        args.state.player = nil
        args.state.cards = nil
        args.state.enemies_destroyed = nil
      end

      args.state.enemies = nil
      args.state.key = nil
      args.state.door = nil
      args.state.mana_chips = nil
      args.state.next_level = false
    end

    def open_door(args, player)
      player.xp += 10
      player.key_found = true
      Enemy.spawn(args, :king)
    end

    def next_map(args, player)
      player.xp += 10
      player.key_found = false
      player.bullets = []
      args.state.current_level += 1
      if args.state.current_level == Level::MAX_LEVEL
        player.contemplating = player.contemplation
        Scene.switch(args, :win)
      else
        args.state.next_level = true
        Scene.switch(args, :level_generation)
      end
    end
  end
end
