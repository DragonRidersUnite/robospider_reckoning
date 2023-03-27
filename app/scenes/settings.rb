module Scene
  class << self
    def tick_settings(args)
      draw_bg(args, DARK_GREEN)
      a_s = args.state

      options = [
        *GameSettings::SETTINGS.map { |s| s.merge(setting_val: a_s.settings[s[:key]]) },
        {
          key: :back,
          on_select: -> (args) { Scene.switch(args, :back) }
        }
      ]

      Menu.tick(args, :settings, options)

      args.outputs.labels <<
        label(:settings, x: args.grid.w / 2, y: args.grid.top - 200, align: ALIGN_CENTER, size: SIZE_LG, font: FONT_BOLD)
    end

    def reset_settings(args)
      Menu.reset_state(args, :settings)
    end
  end
end
