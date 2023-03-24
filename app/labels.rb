module Labels
  class << self
    def controls(args)
      labels = []

      labels << label(
        :controls_title,
        x: args.grid.right - 24,
        y: 112,
        size: SIZE_SM,
        align: ALIGN_RIGHT
      )
      labels <<
        label(
          args.inputs.controller_one.connected ? :controls_gamepad : :controls_keyboard,
          x: args.grid.right - 24,
          y: 76,
          size: SIZE_XS,
          align: ALIGN_RIGHT,
          a: 200
        )
      labels <<
        label(
          args.inputs.controller_one.connected ? :controls2_gamepad : :controls2_keyboard,
          x: args.grid.right - 24,
          y: 48,
          size: SIZE_XS,
          align: ALIGN_RIGHT,
          a: 200
        )

      labels
    end
  end
end
