module Cards
  SIZE = 40
  MARGIN = 0.6 * SIZE
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
          path: Sprite.for(CARDTYPES[0])
        }
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
        path: Sprite.for(type)
      }
    end

    def tick(args, cards, player)

      if cards.length < player.spell_count
        last = ideal_card_spots(cards.length + 1, player).last
        cards << new_card(last.x, last.z, last.angle, CARDTYPES[player.spell_count - 1])
      end

      spots = ideal_card_spots(cards.length, player)

      speed = 0.2
      cards.each_with_index do |card, i|
        spot = spots[i]

        # this right here is very invasive towards the Player object lmao
        if player.mana >= player.spell_cost[i]
          card.merge!({r: nil, g: nil, b: nil})
          if player.spell == i && player.firing
            p = player.spell_delay_counter / 90
            card.x += random(-4 * p, 4 * p)
            card.y += random(-4 * p, 4 * p)
            card.angle += random(-2 * p, 2 * p)
            play_extended_sound(args, :magic, p) if player.spell_delay[i] >= 15
          end

          if i == 1 && player.familiar_limit <= player.familiars.length
            spot.y -= MARGIN
            card.merge!({r: 130, g: 130, b: 130})
          elsif i == 2 && player.max_health <= player.health
            spot.y -= MARGIN
            card.merge!({r: 130, g: 130, b: 130})
          end
        else
          spot.y -= MARGIN
          card.merge!({r: 130, g: 130, b: 130})
        end

        if !player.firing || (player.spell == i && player.mana < player.spell_cost[i])
          exterminate_sound(args, :magic)
        end

        card.x = card.x * (1 - speed) + spot.x * speed
        card.y = card.y * (1 - speed) + spot.y * speed
        card.z = card.z * (1 - speed) + spot.z * speed
        card.angle = card.angle * (1 - speed) + spot.angle * speed
      end
    end

    def ideal_card_spots(total, player)
      selected_card = player.spell
      offset = -((total - 0.1).idiv(2))
      spots = []
      i = 0
      while i < total
        spots << {
          x: 640 + 120 * (i + offset),
          y: -80 - 15 * (i + offset) * (i + offset),
          z: -(i + offset + 0.01).abs,
          angle: -10 * (i + offset)
        }
        i += 1
      end

      return spots.rotate(-selected_card - offset)
    end

    def mock_reload(cards, player)
      cards[player.spell].y -= SIZE * 4
    end

    def draw(deck, player)
      cards = deck.sort_by { |c| c.z }

      cards.map do |card|
        {
          x: card.x - card.w / 2,
          y: card.y,
          w: card.w,
          h: card.h,
          angle: card.angle,
          angle_anchor_x: 0.5,
          path: card.path,
          a: 220,
          r: card.r,
          g: card.g,
          b: card.b
        }
      end
    end
  end
end
