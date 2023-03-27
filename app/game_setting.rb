# different than the Settings scene, this module contains methods for things
# like fullscreen on/off, sfx on/off, etc.
module GameSettings
  class << self
    # returns a string of a hash of settings in the following format:
    # key1:val1,key2:val2
    # `settings` should be a hash of keys and vals to be saved
    def settings_for_save(settings)
      settings
        .map do |k, v|
          "#{k}:#{v}"
        end
        .join(",")
    end

    # we don't want to accidentally ship our debug preferences to our players
    def settings_file
      "settings#{debug? ? "-debug" : nil}.txt"
    end

    # useful when wanting to save settings after the code in the block is
    # executed, ex: `GameSettings.save_after(args) { |args| args.state.settings.big_head_mode = true }
    def save_after(args)
      yield(args)
      save_settings(args)
    end

    # loads settings from disk and puts them into `args.state.settings`
    def load_settings(args)
      settings = args.gtk.read_file(settings_file)&.chomp

      args.state.settings = {
        sfx: true,
        fullscreen: false,
        difficulty: :normal
      }

      if settings
        settings.split(",").map { |s| s.split(":") }.to_h.each do |k, v|
          if v == "true"
            v = true
          elsif v == "false"
            v = false
          else
            v = v.to_sym
          end

          args.state.settings[k.to_sym] = v
        end
      end

      args.gtk.set_window_fullscreen(args.state.settings.fullscreen)
    end

    # saves settings from `args.state.settings` to disk
    def save_settings(args)
      args.gtk.write_file(
        settings_file,
        settings_for_save(args.state.settings)
      )
    end
  end
end
