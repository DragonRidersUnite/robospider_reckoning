module Scene
  class << self
    def tick_settings(args)
      draw_bg(args, DARK_GREEN)
      a_s = args.state

      options = [
        {
          key: :difficulty,
          kind: :toggle,
          setting_val: a_s.settings.difficulty,
          on_select: -> (args) do
            unless a_s.paused.current_option_i
              GameSettings.save_after(args) do |args|
                a_s.settings.difficulty = DIFFICULTY[(DIFFICULTY.index(a_s.settings.difficulty) + 1) % DIFFICULTY.length]
              end
            end
          end
        },
        {
          key: :sfx,
          kind: :toggle,
          setting_val: a_s.settings.sfx,
          on_select: -> (args) do
            GameSettings.save_after(args) do |args|
              a_s.settings.sfx = !a_s.settings.sfx
            end
          end
        },
        {
          key: :back,
          on_select: -> (args) { Scene.switch(args, :back) }
        }
      ]

      if args.gtk.platform?(:desktop)
        options.insert(
          options.length - 1,
          {
            key: :fullscreen,
            kind: :toggle,
            setting_val: a_s.settings.fullscreen,
            on_select: -> (args) do
              GameSettings.save_after(args) do |args|
                a_s.settings.fullscreen = !a_s.settings.fullscreen
                args.gtk.set_window_fullscreen(a_s.settings.fullscreen)
              end
            end
          }
        )
      end

      Menu.tick(args, :settings, options)

      args.outputs.labels <<
        label(:settings, x: args.grid.w / 2, y: args.grid.top - 200, align: ALIGN_CENTER, size: SIZE_LG, font: FONT_BOLD)
    end

    def reset_settings(args)
      Menu.reset_state(args, :settings)
    end
  end
end
