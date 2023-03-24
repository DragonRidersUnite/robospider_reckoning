module Scene
  class << self
    def tick_main_menu(args)
      draw_bg(args, DARK_PURPLE)
      options = [
        {
          key: :start,
          on_select: -> (args) { Scene.switch(args, :level_generation, reset: true) }
        },
        {
          key: :settings,
          on_select: -> (args) { Scene.switch(args, :settings, reset: true, return_to: :main_menu) }
        },
      ]

      if args.gtk.platform?(:desktop)
        options << {
          key: :quit,
          on_select: -> (args) { args.gtk.request_quit }
        }
      end

      Menu.tick(args, :main_menu, options)

      labels = args.outputs.labels
      labels << label(
        title.upcase, x: args.grid.w / 2, y: args.grid.top - 100,
        size: SIZE_LG, align: ALIGN_CENTER, font: FONT_BOLD_ITALIC)
      labels << label(
        :made_by,
        x: args.grid.left + 24, y: args.grid.top - 24,
        size: SIZE_SM, align: ALIGN_LEFT)
      labels << CREDITS.map_with_index do |name, i|
        label(
          name,
          x: args.grid.left + 48, y: args.grid.top - 70 - 25*i,
          size: SIZE_XS, align: ALIGN_LEFT, a: 200)
      end
      labels << Labels.controls(args)
    end

    def reset_main_menu(args)
      Menu.reset_state(args, :paused)
    end
  end
end
