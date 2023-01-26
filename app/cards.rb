module Cards
  SIZE = 80
  WIDTH = 2.5 * SIZE
  HEIGHT = 3.5 * SIZE
  CARDTYPES = [:bullet_card, :familiar_card, :heal_card, :bomb_card, :joker_card]

  class << self
    def create(args)
      [
        {
          x: 640,
          y: -360,
          z: 0,
          angle: 0,
          w: WIDTH,
          h: HEIGHT,
          path: Sprite.for(CARDTYPES[0]), 
        },
      ]
    end

    def new_card(x, z, angle, type)
      {
        x: x,
        y: -360,
        z: z,
        angle: angle,
        w: WIDTH,
        h: HEIGHT,
        path: Sprite.for(type), 
	  }
    end

    def tick(cards, player)

      if cards.length < player.spell_count
        last = ideal_card_spots(cards.length + 1, player).last
        cards << new_card(last.x, last.z, last.angle, CARDTYPES[player.spell_count-1])
      end

      spots = ideal_card_spots(cards.length, player)

      speed = 0.2
      cards.each_with_index do |card, i|
        spot = spots[i]

        if player.mana >= player.spell_cost[i]
          if player.spell == i && player.firing
            card.x += random(-3, 3)
            card.y += random(-3, 3)
            card.angle += random(-1, 1)
          end
        else
          spot.y -= 150
        end

        card.x = card.x * (1-speed) + spot.x * speed
        card.y = card.y * (1-speed) + spot.y * speed
        card.z = card.z * (1-speed) + spot.z * speed
        card.angle = card.angle * (1-speed) + spot.angle * speed

      end
    end

    def ideal_card_spots(total, player)
      selected_card = player.spell
      offset = -((total-0.1).idiv(2))
      spots = []
      i = 0
      while i < total
        spots << {
          x: 640 + 120 * (i + offset),
          y: -80 - 15 * (i+offset) * (i+offset),
          z: -(i + offset + 0.01).abs,
          angle: -10 * (i + offset),
        }
        i += 1
      end
      return spots.rotate(-selected_card-offset)
    end

    def mock_reload(cards, player)
      cards[player.spell].y -= 300
    end

    def draw(deck, player)
      cards = deck.sort_by{|c| c.z}

      to_render = []
      cards.each do |card|
        to_render << {
          x: card.x - card.w/2,
          y: card.y,
          w: card.w,
          h: card.h,
          angle: card.angle,
          angle_anchor_x: 0.5,
          path: card.path,
		  a: 220,
        }
      end
      return to_render
    end
  end
end