module Scene
  class << self
  # Shown after the player dies
    def tick_game_over(args)
      draw_bg(args, DARK_BLUE)

      player = args.state.player
      labels = []

      labels << label(:game_over, x: args.grid.w / 2, y: args.grid.top - 180, align: ALIGN_CENTER, size: SIZE_LG, font: FONT_BOLD)
      labels <<
        label("#{text(:level)}: #{player.level}", x: args.grid.w / 2, y: args.grid.top - 300, size: SIZE_SM, align: ALIGN_CENTER)
      labels <<
        label(
          "#{text(:enemies_destroyed)}: #{args.state.enemies_destroyed}",
          x: args.grid.w / 2,
          y: args.grid.top - 360,
          size: SIZE_SM,
          align: ALIGN_CENTER
        )
      labels <<
        label(
          "#{text(:difficulty)}: #{text(args.state.setting.difficulty)}",
          x: args.grid.w / 2,
          y: args.grid.top - 420,
          size: SIZE_SM,
          align: ALIGN_CENTER
        )

      if (player.contemplating -= 1) < 0
        labels <<
          label(:restart, x: args.grid.w / 2, y: args.grid.top - 520, align: ALIGN_CENTER, size: SIZE_SM)
            .merge(a: args.tick_count % 155 + 100)

        if Input.confirm?(args.inputs)
          return Scene.switch(args, :level_generation, reset: true)
        end
      end

      args.outputs.labels << labels
    end
  end
end
