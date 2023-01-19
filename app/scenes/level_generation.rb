module Scene
  class << self
    def tick_level_generation(args)
      draw_bg(args, DARK_GOLD)

      args.state.level_generation ||= Level.generate_fiber

      result = args.state.level_generation.resume(100)

      if result
        args.state.level_generation = nil
        args.state.level = result
        Scene.switch(args, :gameplay, reset: true)
        return
      end

      label = label(:generating_level, x: (args.grid.w / 2) - 200, y: args.grid.top - 200, size: SIZE_LG, font: FONT_BOLD)
      label[:text] += "." * (args.state.tick_count.idiv(20) % 4)
      args.outputs.labels << label
    end
  end
end
