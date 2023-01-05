# returns a string of a hash of settings in the following format:
# key1=val1,key2=val2
# `settings` should be a hash of keys and vals to be saved
def settings_for_save(settings)
  settings.map do |k, v|
    "#{k}:#{v}"
  end.join(",")
end

def settings_file
  "settings#{ debug? ? '-debug' : nil}.txt"
end

def toggle_fullscreen(args)
  args.state.setting.fullscreen = !args.state.setting.fullscreen
  args.gtk.set_window_fullscreen(args.state.setting.fullscreen)
end

def load_settings(args)
  settings = args.gtk.read_file(settings_file).chomp

  if settings
    settings.split(",").map { |s| s.split(":") }.to_h.each do |k, v|
      if v == "true"
        v = true
      elsif v == "false"
        v = false
      end
      args.state.setting[k.to_sym] = v
    end
  else
    args.state.setting.sfx = true
    args.state.setting.fullscreen = false
  end

  if args.state.setting.fullscreen
    args.gtk.set_window_fullscreen(args.state.setting.fullscreen)
  end
end

def save_settings(args)
  args.gtk.write_file(
    settings_file,
    settings_for_save(open_entity_to_hash(args.state.setting))
  )
end
