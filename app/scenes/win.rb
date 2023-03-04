module Scene
  class << self
    # Shown after the player wins
    def tick_win(args)
      a_s = args.state
      draw_bg(args, BLACK)
      fireworks = a_s.fireworks ||= Fireworks.create

      labels = []

      labels << label(:win, x: args.grid.w / 2, y: args.grid.top - 200, align: ALIGN_CENTER, size: SIZE_LG, font: FONT_BOLD)
      labels << label("#{text(:level)}: #{a_s.player.level}", x: args.grid.w / 2, y: args.grid.top - 320, size: SIZE_SM, align: ALIGN_CENTER)
      labels << label("#{text(:enemies_destroyed)}: #{a_s.enemies_destroyed}", x: args.grid.w / 2, y: args.grid.top - 380, size: SIZE_SM, align: ALIGN_CENTER)

      if (a_s.player.contemplating-=1) < 0
        labels << label(:retry, x: args.grid.w / 2, y: args.grid.top - 480, align: ALIGN_CENTER, size: SIZE_SM).merge(a: a_s.tick_count % 155 + 100)

        if Input.confirm?(args.inputs)
          Fireworks.extinguish(fireworks)
          return Scene.switch(args, :level_generation)
        end
      end

      Fireworks.launch(fireworks, 1) if args.tick_count.mod_zero?(3)
      Fireworks.tick(args, fireworks)

      args.outputs.labels << labels
    end
  end
end
