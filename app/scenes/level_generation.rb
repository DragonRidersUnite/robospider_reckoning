module Scene
  class << self
    def tick_level_generation(args)
      draw_bg(args, DARK_GOLD)
      a_s = args.state

      a_s.current_level ||= 0
      a_s.level_generation ||= Level.generate_calculation

      if a_s.level
        args.outputs.labels << [
          label("Entering Sublevel X#{a_s.current_level + 1}", x: args.grid.w / 2, y: 512, color: WHITE, align: ALIGN_CENTER),
          label(Level::NAMES[a_s.current_level], x: args.grid.w / 2, y: 480, size: SIZE_LG, font: FONT_BOLD, color: WHITE, align: ALIGN_CENTER)
        ]

        options = [
          {
            key: :start,
            on_select: -> (args) { Scene.switch(args, :gameplay, reset: true) }
          },
        ]
        Menu.tick(args, :main_menu, options)
      else
        result = a_s.level_generation.run_for_ms(15)

        if result
          a_s.level_generation = nil
          a_s.level = result
          if a_s.current_level == 0
            Scene.switch(args, :gameplay, reset: true)
            return
          end
        end
        args.outputs.labels << [
          label(:generating_level, x: args.grid.w / 2, y: 512, color: WHITE, align: ALIGN_CENTER),
          label("." * (a_s.tick_count.idiv(20) % 4), x: args.grid.w / 2, y: 480, size: SIZE_LG, font: FONT_BOLD, color: WHITE, align: ALIGN_CENTER)
        ]
      end
    end

    def reset_level_generation(args)
      args.state.level = nil
      args.state.current_level = nil
    end
  end
end
