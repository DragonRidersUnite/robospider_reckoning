module Scene
  class << self
    def tick_settings(args)
      draw_bg(args, DARK_GREEN)
      a_s = args.state

      options = [
        {
          key: :sfx,
          kind: :toggle,
          setting_val: a_s.setting.sfx,
          on_select: -> (args) do
            GameSetting.save_after(args) do |args|
              a_s.setting.sfx = !a_s.setting.sfx
            end
          end
        },
        {
          key: :back,
          on_select: -> (args) { Scene.switch(args, :back) }
        },
      ]

      if args.gtk.platform?(:desktop)
        options.insert(options.length - 1, {
          key: :fullscreen,
          kind: :toggle,
          setting_val: a_s.setting.fullscreen,
          on_select: -> (args) do
            GameSetting.save_after(args) do |args|
              a_s.setting.fullscreen = !a_s.setting.fullscreen
              args.gtk.set_window_fullscreen(a_s.setting.fullscreen)
            end
          end
        })
      end

      Menu.tick(args, :settings, options)

      args.outputs.labels << label(:settings, x: args.grid.w / 2, y: args.grid.top - 200, align: ALIGN_CENTER, size: SIZE_LG, font: FONT_BOLD)
    end

    def reset_settings(args)
      Menu.reset_state(args, :settings)
    end
  end
end
