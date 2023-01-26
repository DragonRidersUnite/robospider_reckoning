def play_sfx(args, key)
  if args.state.setting.sfx
    args.outputs.sounds << "sounds/#{key}.wav"
  end
end

def play_extended_sound(args, key, vol)
  if args.state.setting.sfx
    args.audio[key] ||= {
      input: "sounds/#{key}.wav",
      looping: true
    }
    args.audio[key].gain = vol
  end
  args.audio[key] = false if vol <= 0
end

def exterminate_sound(args, key)
  args.audio[key] = false
end