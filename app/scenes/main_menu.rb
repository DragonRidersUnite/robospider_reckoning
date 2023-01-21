module Scene
  class << self
    def tick_main_menu(args)
      draw_bg(args, DARK_PURPLE)
      options = [
        {
          key: :start,
          on_select: -> (args) { Scene.switch(args, :level_generation) }
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
        "#{text(:made_by)} #{(CREDITS-[CREDITS.last]).join(', ')}, and #{CREDITS.last}",
        x: args.grid.left + 24, y: 48,
        size: SIZE_XS, align: ALIGN_LEFT)
      labels << label(
        :controls_title,
        x: args.grid.right - 24, y: 112,
        size: SIZE_SM, align: ALIGN_RIGHT)
      labels << label(
        args.inputs.controller_one.connected ? :controls_gamepad : :controls_keyboard,
        x: args.grid.right - 24, y: 76,
        size: SIZE_XS, align: ALIGN_RIGHT)
      labels << label(
        args.inputs.controller_one.connected ? :controls2_gamepad : :controls2_keyboard,
        x: args.grid.right - 24, y: 48,
        size: SIZE_XS, align: ALIGN_RIGHT)
    end
  end
end
