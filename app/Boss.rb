module Boss
  X_OFFSET = 30  # (sprite.w - body.w) / 2    for now
  Y_OFFSET = 18  # (sprite.h - body.h) / 2    for now
  40x64
  class << self
    def create(args, player)
      lo = Level::CELL_SIZE
      hi = (Level::MAZE_SIZE-1) * lo
      x = (player.x + (player.x < hi/2 ? hi : lo)) / 2
      y = (player.y + (player.y < hi/2 ? hi : lo)) / 2

      b = {
        x: x,
        y: y,
        w: 40,
        h: 64,      # body as hitbox
        angle: 0,
        path: Sprite.for(:boss),
        sprite: {
          x: x - X_OFFSET,
          y: y - Y_OFFSET,
          w: 100,
          h: 100,
          path: Sprite.for(:boss),
          angle: 0,
        },         # display 

        dead: false,
        target: false,
        mode: :idle,
        attention_span: 40,
        attention_counter: 0,
        delay_time: 30,
        delay_counter: 0,
        health: 64,     
        base_health: 64,
        max_health: 150,
        min_mana_drop: 30,
        max_mana_drop: 50,
        speed: 3,
        body_power: 30,
        xp: 100,
        pass_walls: true,
      }
      b
    end

    def tick(args, boss)
      # Ideas: use or make up own, its your call.
      #   if < half health hunt for bugs to eat
      #   if can't see player hunt for bugs to eat, unless > 90% health
      #   if see player attack routines
      #     move to jump range, then jump (telegraph target area)
      #       jump trails dragline (disappear when land)
      #     if jumping and player move, follow player but miss,
      #       landng so player between end of forelegs
      #     jump to ceiling, shadow darken as approach jump-distance, jump down feed/attack
      #   if can't see player && health > 90% then idle
    end

    def drain_life(args, boss, enemy)
      boss.health += enemy.base_health
      enemy.health -= enemy.base_health
      boss.health += enemy.health if enemy.health <= boss.body_power
    end

    def damage(args, boss, entity, sfx: nil)
      boss.health -= entity.power || entity.body_power
      flash(boss[:sprite], RED, 12)
      play_sfx(args, sfx) if sfx
      boss.dead = true if boss.health < 0  # boss desperately clings to life
    end

    def absorb_mana(args, boss, m_c)
      boss.body_power += m_c.exp_amount if rand(3) == 0
    end
  end
end
