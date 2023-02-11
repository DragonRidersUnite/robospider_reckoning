module Scene
  class << self
    def tick_level_generation(args)
      draw_bg(args, DARK_GOLD)

      args.state.level_generation ||= Level.generate_calculation

      result = args.state.level_generation.run_for_ms(15)

      if result
        args.state.level_generation = nil
        args.state.level = result
        reset = args.state.player ? args.state.player.dead? : true
        if reset
          args.state.player.x = result[:start_position][:x]
          args.state.player.y = result[:start_position][:y]
        end
        Scene.switch(args, :gameplay, reset: reset)
        return
      end

      label = label(:generating_level, x: (args.grid.w / 2) - 200, y: args.grid.top - 200, size: SIZE_LG, font: FONT_BOLD)
      label[:text] += "." * (args.state.tick_count.idiv(20) % 4)
      args.outputs.labels << label
    end
  end
end
