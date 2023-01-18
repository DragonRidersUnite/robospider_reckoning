# efficient input helpers that all take `args.inputs`
module Input
  PRIMARY_KEYS = [:j, :z, :space]
  PAUSE_KEYS = [:escape, :p]

  class << self
    def confirm?(inputs)
      PRIMARY_KEYS.any? { |k| inputs.keyboard.key_down.send(k) } ||
        inputs.controller_one.key_down&.a
    end

    def fire?(inputs)
      PRIMARY_KEYS.any? { |k| inputs.keyboard.key_held.send(k) } ||
        inputs.controller_one.key_held&.a
    end

    def pause?(inputs)
      PAUSE_KEYS.any? { |k| inputs.keyboard.key_down.send(k) } ||
        inputs.controller_one.key_down&.start
    end

    def toggle_minimap?(inputs)
      inputs.keyboard.key_down.m || inputs.controller_one.key_down&.y
    end

    def window_out_of_focus?(inputs)
      !inputs.keyboard.has_focus
    end
  end
end
