# efficient input helpers that all take `args.inputs`
module Input
  PRIMARY_KEYS = [:j, :z, :space]
  SECONDARY_KEYS = [:k, :x, :backspace]
  INVERT_KEYS = [:f]

  NAV_LEFT_KEYS = [:h,:u,:c, :q]
  NAV_RIGHT_KEYS = [:l,:i,:v, :e]
  PAUSE_KEYS = [:escape, :p]

  class << self
    def confirm?(inputs)
      PRIMARY_KEYS.any? { |k| inputs.keyboard.key_down.send(k) } || inputs.controller_one.key_down&.a
    end

    def cancel?(inputs)
      SECONDARY_KEYS.any? { |k| inputs.keyboard.key_down.send(k) } || inputs.controller_one.key_down&.b
    end

    def fire?(inputs)
      PRIMARY_KEYS.any? { |k| inputs.keyboard.key_down.send(k) } ||
        PRIMARY_KEYS.any? { |k| inputs.keyboard.key_held.send(k) } ||
        inputs.controller_one.key_down&.a ||
        inputs.controller_one.key_held&.a
    end

    def rush?(inputs)
      SECONDARY_KEYS.any? { |k| inputs.keyboard.key_down.send(k) || inputs.keyboard.key_held.send(k) } ||
        inputs.controller_one.key_down&.b ||
        inputs.controller_one.key_held&.b
    end

    def invertTurret?(inputs)
      inputs.controller_one.key_down.x ||
        INVERT_KEYS.any? { |k| inputs.keyboard.key_down.send(k)}
    end

    def movement?(inputs)
      {x: inputs.left_right, y: inputs.up_down}
    end

    def secondary_navigation?(inputs)
      (nav_right?(inputs) ? 1 : 0) - (nav_left?(inputs) ? 1 : 0)
    end

    def nav_right?(inputs)
      inputs.controller_one.key_down.r1 ||
        inputs.controller_one.key_down.r2 ||
        inputs.controller_one.key_down.r3 ||
        NAV_RIGHT_KEYS.any? { |k| inputs.keyboard.key_down.send(k)  }

    end

    def nav_left?(inputs)
      inputs.controller_one.key_down.l1 ||
        inputs.controller_one.key_down.l2 ||
        inputs.controller_one.key_down.l3 ||
        NAV_LEFT_KEYS.any? { |k| inputs.keyboard.key_down.send(k)  }
    end

    def pause?(inputs)
      PAUSE_KEYS.any? { |k| inputs.keyboard.key_down.send(k) } || inputs.controller_one.key_down&.start
    end

    def toggle_minimap?(inputs)
      inputs.keyboard.key_down.m || inputs.controller_one.key_down&.y
    end

    def window_out_of_focus?(inputs)
      !inputs.keyboard.has_focus
    end
  end
end
