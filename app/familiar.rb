module Familiar
  class << self
    def spawn(player, dist_from_player:, speed: 18)
      familiar = {
        x: player.x + 10,
        y: player.y,
        w: 18,
        h: 18,
        power: 2,
        cooldown_countdown: 0,
        cooldown_ticks: 10,
        speed: speed,
        dist_from_player: dist_from_player,
        path: Sprite.for(:familiar),
      }
      player.familiars << familiar
      familiar
    end

    def tick(args, player, familiar)
      rotator = args.state.tick_count / familiar.speed
      familiar.x = player.x + player.w / 2 - familiar.w / 2 + Math.sin(rotator) * familiar.dist_from_player
      familiar.y = player.y + player.h / 2 - familiar.h / 2 + Math.cos(rotator) * familiar.dist_from_player
      familiar.angle = args.geometry.angle_to(player, familiar)
      if familiar.cooldown_countdown > 0
        familiar.a = 255 / 2
      else
        familiar.a = nil
      end
      familiar.cooldown_countdown -= 1
      familiar
    end
  end
end
