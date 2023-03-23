module Scene
  class << self
    # Shown after the player wins
    def tick_win(args)
      a_s = args.state
      fireworks = a_s.fireworks ||= Fireworks.create
      draw_bg(args, BLACK)

      labels = []

      labels << label(:win, x: args.grid.w / 2, y: args.grid.top - 180, align: ALIGN_CENTER, size: SIZE_LG, font: FONT_BOLD)
      labels << label("#{text(:level)}: #{a_s.player.level}", x: args.grid.w / 2, y: args.grid.top - 300, size: SIZE_SM, align: ALIGN_CENTER)
      labels << label("#{text(:enemies_destroyed)}: #{a_s.enemies_destroyed}", x: args.grid.w / 2, y: args.grid.top - 360, size: SIZE_SM, align: ALIGN_CENTER)
      labels << label("#{text(:difficulty)}: #{text(args.state.setting.difficulty)}", x: args.grid.w / 2, y: args.grid.top - 420, size: SIZE_SM, align: ALIGN_CENTER)

      if (a_s.player.contemplating -= 1) < 0
        labels << label(:retry, x: args.grid.w / 2, y: args.grid.top - 520, align: ALIGN_CENTER, size: SIZE_SM).merge(a: a_s.tick_count % 155 + 100)

        if Input.confirm?(args.inputs)
          fireworks = []
          return Scene.switch(args, :level_generation)
        end
      end

      if args.tick_count.mod_zero?(3)
        Fireworks.launch(fireworks, args)
      end

      Fireworks.tick(fireworks, args)

      args.outputs.labels << labels
    end
  end
end
