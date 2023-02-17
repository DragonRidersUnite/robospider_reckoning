module Sprite
  # annoying to track but useful for reloading with +i+ in debug mode; would be
  # nice to define a different way
  SPRITES = {
    key: "sprites/key.png",
    door: "sprites/door.png",
    player: "sprites/player.png",
    bullet: "sprites/bullet.png",
    familiar: "sprites/familiar.png",
    bomb: "sprites/bomb.png",
    bullet_card: "sprites/card/bullet.png",
    familiar_card: "sprites/card/familiar.png",
    heal_card: "sprites/card/heal.png",
    bomb_card: "sprites/card/bomb.png",
    joker_card: "sprites/card/joker.png",
    mana_chip: "sprites/mana_chip.png",
    enemy: "sprites/enemy/basic.png",
    enemy_super: "sprites/enemy/super.png",
    enemy_king: "sprites/enemy/king.png",
    hud: "sprites/hud.png",
  }

  class << self
    def reset_all(args)
      SPRITES.each_value { |v| args.gtk.reset_sprite(v) }
    end

    def for(key)
      SPRITES.fetch(key)
    end
  end
end

