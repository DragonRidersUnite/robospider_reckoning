module Hud
  HEIGHT = 80
  BAR_X = 42
  BAR_H = 20
  HEALTH_BAR_Y = HEIGHT - 10
  ENERGY_BAR_Y = HEIGHT - 42
  XP_BAR_Y = HEIGHT - 69
  BAR_W = 334 - BAR_X
  HEALTH_BAR_COLOR = { r: 106, g: 190, b: 48 }
  HEALTH_BAR_BG = { r: 172, g: 50, b: 50 }
  ENERGY_BAR_COLOR = { r: 95, g: 205, b: 228 }
  ENERGY_BAR_BG = { r: 89, g: 86, b: 82 }
  XP_BAR_COLOR = { r: 223, g: 113, b: 38 }
  XP_BAR_BG = { r: 69, g: 40, b: 60 }

  def self.draw(args, player, level, key, door, enemies, cards)
    args.outputs.sprites << [{
      x: BAR_X,
      y: HEALTH_BAR_Y - BAR_H,
      w: BAR_W,
      h: BAR_H
    }.solid!(HEALTH_BAR_BG), {
      x: BAR_X,
      y: HEALTH_BAR_Y - BAR_H,
      w: (player.health / player.max_health * BAR_W).ceil,
      h: BAR_H
    }.solid!(HEALTH_BAR_COLOR), {
      x: BAR_X,
      y: ENERGY_BAR_Y - BAR_H,
      w: BAR_W,
      h: BAR_H
    }.solid!(ENERGY_BAR_BG), {
      x: BAR_X,
      y: ENERGY_BAR_Y - BAR_H,
      w: (player.mana / player.max_mana * BAR_W).ceil,
      h: BAR_H
    }.solid!(ENERGY_BAR_COLOR), {
      x: BAR_X,
      y: XP_BAR_Y - BAR_H,
      w: BAR_W,
      h: BAR_H
    }.solid!(XP_BAR_BG), {
      x: BAR_X,
      y: XP_BAR_Y - BAR_H,
      w: (player.xp / player.xp_needed * BAR_W).ceil,
      h: BAR_H
    }.solid!(XP_BAR_COLOR), {
      x: 0,
      y: 0,
      w: 1280,
      h: 80,
      path: Sprite.for(:hud)
    }]
    Minimap.draw(args, level: level, player: player, artifact: player.key_found ? door : key, enemies: enemies)
    args.outputs.sprites << Cards.draw(cards, player)
  end
end
