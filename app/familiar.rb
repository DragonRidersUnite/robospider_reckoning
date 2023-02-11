module Familiar
  class << self
    def spawn(player)
      familiar = {
        x: player.x + 10,
        y: player.y,
        w: 18,
        h: 18,
        power: 2,
        cooldown_countdown: 0,
        cooldown_ticks: 10,
        health: 3,
        dist_from_player: 40,
        angle: 0,
        path: Sprite.for(:familiar),
      }
      player.familiars << familiar
      familiar
    end

    def tick(args, player, familiar, index)
      desired_angle = (player.familiar_angle + index * (360 / player.familiars.length)) % 360
      discrepancy = (desired_angle - familiar.angle + 180) % 360 - 180

      move_speed = 0.1 * discrepancy

      familiar.angle = (familiar.angle + move_speed) % 360

      rotator = -familiar.angle * Math::PI / 180
      familiar.x = player.x + player.w / 2 - familiar.w / 2 + Math.sin(rotator) * familiar.dist_from_player
      familiar.y = player.y + player.h / 2 - familiar.h / 2 + Math.cos(rotator) * familiar.dist_from_player
      familiar.a = familiar.cooldown_countdown > 0 ? 128 : 255
      familiar.cooldown_countdown -= 1
      familiar.dead = true if familiar.health <= 0

      familiar
    end
  end
end
