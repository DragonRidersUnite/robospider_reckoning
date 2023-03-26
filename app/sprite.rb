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
    enemy: "sprites/enemy/basic-sheet.png",
    enemy_super: "sprites/enemy/super-sheet.png",
    enemy_king: "sprites/enemy/king-sheet.png",
    boss: "sprites/enemy/boss-sheet.png",
    hud: "sprites/hud.png"
  }

  INFO = {
    SPRITES[:enemy] => {
      idle: {
        loop: false,
        frames: 1,
        duration: 1,
        x: 0,
        y: 0,
        w: 32,
        h: 96
      },
      flying: {
        loop: true,
        frames: 2,
        duration: 1,
        x: 32,
        y: 0,
        w: 32,
        h: 96
      },
      w: 96,
      h: 96
    },
    SPRITES[:enemy_super] => {
      idle: {
        loop: false,
        frames: 1,
        duration: 1,
        x: 0,
        y: 0,
        w: 32,
        h: 96
      },
      flying: {
        loop: true,
        frames: 2,
        duration: 1,
        x: 32,
        y: 0,
        w: 32,
        h: 96
      },
      w: 96,
      h: 96
    },
    SPRITES[:enemy_king] => {
      idle: {
        loop: false,
        frames: 1,
        duration: 1,
        x: 0,
        y: 0,
        w: 32,
        h: 96
      },
      flying: {
        loop: true,
        frames: 2,
        duration: 1,
        x: 32,
        y: 0,
        w: 32,
        h: 96
      },
      w: 96,
      h: 96
    }
  }

  class << self
    def reset_all(args)
      SPRITES.each_value { |v| args.gtk.reset_sprite(v) }
    end

    def for(key)
      SPRITES.fetch(key)
    end

    def info(key)
      INFO.fetch(key)
    end
  end
end
