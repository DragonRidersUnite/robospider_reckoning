module Scene
  MAXIMUM_ENEMIES = 80
  class << self
    def tick_gameplay(args)
      a_s = args.state
      level = a_s.level
      player = a_s.player ||= Player.create(args, x: level[:start_position][:x], y: level[:start_position][:y])
      key = a_s.key ||= Artifact.create(args, :key)
      door = a_s.door ||= Artifact.create(args, :door)
      cards = a_s.cards ||= Cards.create(args)
      camera = a_s.camera ||= Camera.build
      enemies = a_s.enemies ||= []
      boss = a_s.boss ||= {}
      boss.merge!(Boss.create(args, player)) if boss.empty? && a_s.current_level == Level::BOSS_LEVEL
      a_s.enemies_destroyed ||= 0
      a_s.mana_chips ||= []
      enemy_spawn_timer = a_s.enemy_spawn_timer ||= Timer.every(60)

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

      enemies.each { |e| Enemy.tick(args, e, player, level) }
      a_s.mana_chips.each { |c| ManaChip.tick(args, c) }

      # TODO: Use some kind of spatial hash (quadtree?) to speed this up?
      Collision.detect(player, level[:walls]) do |player, wall|
        Collision.move_out_of_collider(player, wall)
      end

      Collision.detect(player.bullets, level[:walls]) do |bullet, wall|
        #bullet.angle *= -1

        #calculate where the bullet was prior to collision
        vx,vy = vel_from_angle(bullet.angle, bullet.speed)
        bx = bullet.x - vx
        by = bullet.y - vy

        #vertial wall hit
        bullet.angle = 0 - bullet.angle if  by + bullet.h <= wall.y ||
        by >= wall.y+ wall.h
        #horizontal wall hit
        bullet.angle = 180 - bullet.angle if bx + bullet.w <= wall.x ||
        bx >= wall.x+ wall.w
        #bullet.dead = true
        #level[:walls].delete_at(level[:walls].index(wall))
      end

      unless a_s.enemies_pass_walls
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
        Player.enemy_knockback(args, player, enemy)
        camera.shake
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

      Collision.detect(a_s.mana_chips, player) do |mana_chip, _|
        mana_chip.dead = true
        Player.absorb_mana(args, player, mana_chip)
        play_sfx(args, :mana_chip)
      end

      Collision.detect(player, key) { |player, _| open_door(args, player) } unless player.key_found
      Collision.detect(player, door.merge(y: door.y - 2)) { |player, _| return next_map(args, player) } if player.key_found

      enemies.reject!(&:dead)
      a_s.mana_chips.reject!(&:dead)
      player.familiars.reject!(&:dead)

      if !boss.empty?
        Boss.tick(args, boss, enemies, player)

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
          Player.enemy_knockback(args, player, b)
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

        Collision.detect(a_s.mana_chips, boss) do |mana_chip, boss|
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
        player.complete = false
        exterminate_sounds(args)
        play_sfx(args, :level_up)
        a_s.current_level = Level::BOSS_LEVEL - 1
        next_map(args, player)
      end

      Camera.follow(camera, target: player, bounds: level[:bounds])

      draw_bg(args, BLACK)
      Level.draw(args, level, camera)

      args.outputs.sprites <<
        [
          Camera.translate(camera, a_s.mana_chips),
          Camera.translate(camera, a_s.player.bullets),
          Camera.translate(camera, enemies),
          Camera.translate(camera, a_s.player.familiars),
          Camera.translate(camera, door),
          Camera.translate(camera, a_s.player.effects.flat_map { _1.particles })
        ]
      args.outputs.sprites << Camera.translate(camera, boss[:sprite]) if !boss.empty?
      args.outputs.sprites << Camera.translate(camera, key) unless player.key_found
      LeggedCreature.render(args, player, camera)

      Hud.tick(args)
      Hud.draw(args, player, level, key, door, enemies, cards)
    end

    def reset_gameplay(args)
      a_s = args.state
      if a_s.next_level
        a_s.player.x = a_s.level[:start_position][:x]
        a_s.player.y = a_s.level[:start_position][:y]
      else
        a_s.camera = nil
        a_s.player = nil
        a_s.cards = nil
        a_s.enemies_destroyed = nil
      end

      a_s.enemies = nil
      a_s.key = nil
      a_s.door = nil
      a_s.mana_chips = nil
      a_s.next_level = false
    end

    def open_door(args, player)
      player.xp += 10
      player.key_found = true
      Enemy.spawn(args, :king)
    end

    def next_map(args, player)
      a_s = args.state
      player.xp += 10
      player.key_found = false
      player.bullets = []
      a_s.current_level += 1
      if a_s.current_level == Level::MAX_LEVEL
        player.contemplating = player.contemplation
        Scene.switch(args, :win)
      else
        a_s.next_level = true
        Scene.switch(args, :level_generation)
      end
    end
  end
end
