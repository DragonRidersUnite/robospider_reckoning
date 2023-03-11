module ManaChip
  class << self
    def create(enemy)
      {
        x: enemy.x + (enemy.w / 2) + (-5..5).to_a.sample,
        y: enemy.y + (enemy.h / 2) + (-5..5).to_a.sample,
        speed: 6,
        angle: rand(360),
        w: 12,
        h: 12,
        dead: false,
        exp_amount: 1,
        path: Sprite.for(:mana_chip)
      }
    end
    
    def animate(args, mana_chip)
      mana_chip.angle += 1
      mana_chip.w = 12 + 2 * Math.sin(args.state.tick_count / 20)
      mana_chip.h = 12 + 2 * Math.sin(args.state.tick_count / 20)
    end

    def tick(args, mana_chip)
      animate(args, mana_chip)
      
      player = args.state.player
      if args.geometry.distance(mana_chip, player) <= player.mana_chip_magnetic_dist
        mana_chip.angle = args.geometry.angle_to(mana_chip, player)
        mana_chip.speed = player.speed + 1
      end

      if mana_chip.speed >= 1
        mana_chip.x_vel, mana_chip.y_vel = vel_from_angle(mana_chip.angle, mana_chip.speed)

        mana_chip.x += mana_chip.x_vel
        mana_chip.y += mana_chip.y_vel
        mana_chip.speed -= 1
      end
    end
  end
end
