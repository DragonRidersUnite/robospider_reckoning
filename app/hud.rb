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

  def self.tick(args)
    args.state.hud ||= { large_minimap: false,
                         minimap_ease: 0 }
    hud = args.state.hud

    hud.large_minimap ^= true if Input.toggle_minimap?(args.inputs)
    hud.minimap_ease = hud.minimap_ease.towards((hud.large_minimap ? 1 : 0), 0.1)
  end

  def self.draw(args, player, level, key, door, enemies, cards)
    hud = args.state.hud

    minimap_ease = hud.minimap_ease
    minimap_factor = lerp(Minimap::FACTOR_SM, Minimap::FACTOR_LG, minimap_ease)
    minimap_size = Minimap.size(factor: minimap_factor, level: level)

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
      },
      Cards.draw(cards, player)
    ]
    Minimap.draw(args,
                 x: lerp(args.grid.right - minimap_size.w - 10,
                         args.grid.right - minimap_size.w,
                         minimap_ease),
                 y: lerp(10, 80, minimap_ease),
                 factor: minimap_factor,
                 level: level, player: player, artifact: player.key_found ? door : key, enemies: enemies)
    args.outputs.labels << [
      label("Sublevel X#{args.state.current_level + 1}", x: lerp(1168, 1270, minimap_ease), y: 72, color: WHITE, align: ALIGN_RIGHT),
      label(Level::NAMES[args.state.current_level], x: lerp(1168, 1270, minimap_ease), y: 48, size: SIZE_LG, font: FONT_BOLD, color: WHITE, align: ALIGN_RIGHT)
    ]
  end
end
