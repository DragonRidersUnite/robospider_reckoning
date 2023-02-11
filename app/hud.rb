module Hud
  TOP = 80
  BAR_X = 30
  BAR_Y = 9
  BAR_W = 157
  BAR_H = 16
  HEALTH_BAR_COLOR = { r: 172, g: 50, b: 50 }
  MANA_BAR_COLOR = { r: 99, g: 155, b: 255 }

  def self.draw(args, player, level, key, door, enemies, cards)
    args.outputs.sprites << { x: 0, y: 0, w: 1280, h: TOP }.solid!(BLACK)

    Minimap.draw(args, level: level, player: player, artifact: player.key_found ? door : key, enemies: enemies)
    args.outputs.sprites << Cards.draw(cards, player)
    args.outputs.labels << [
      label("Level #{player.level}", x: 800, y: TOP),
      label("#{player.xp} / #{player.xp_needed}", x: 800, y: TOP - 32),
    ]

    args.outputs.sprites << [{
      x: 10,
      y: TOP - 32,
      w: 192,
      h: 32,
      path: Sprite.for(:health)
    }, {
      x: 10 + BAR_X,
      y: TOP - 32 + BAR_Y,
      w: (player.health / player.max_health * BAR_W).ceil,
      h: BAR_H
    }.solid!(HEALTH_BAR_COLOR), {
      x: 10,
      y: TOP - 64,
      w: 192,
      h: 32,
      path: Sprite.for(:mana)
    }, {
      x: 10 + BAR_X,
      y: TOP - 64 + BAR_Y,
      w: (player.mana / player.max_mana * BAR_W).ceil,
      h: BAR_H
    }.solid!(MANA_BAR_COLOR)]
  end
end
