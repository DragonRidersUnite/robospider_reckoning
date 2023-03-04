module Boss
  X_OFFSET = 0  # (sprite.w - body.w) / 2    for now
  Y_OFFSET = 0  # (sprite.h - body.h) / 2    for now
  class << self
    def create(args, x, y)
      b = {
        x: x,
        y: y,
        w: 0,
        h: 0,      # body as hitbox
        angle: 0,
        sprite: {
          x: x - X_OFFSET,
          y: y - Y_OFFSET,
          w: 0,
          h: 0,
          path:,
          angle: 0,
        },         # display 

        dead: false,
        target: false,
        mode: :idle,
        attention_span: 40,
        attention_counter: 0,
        delay_time: 30,
        delay_counter: 0,
        health: 1,
        base_health: 1,
        max_health: 1,
        path: Sprite.for(:enemy),
        min_mana_drop: 1,
        max_mana_drop: 4,
        speed: 3,
        body_power: 1,
        xp: 1,
      }
      b
    end

    def tick(args, boss)
    end

    def damage(args, boss, attacker, sfx = nil)
    end

    def absorb_mana(args, boss, m_c)
    end
  end
end
