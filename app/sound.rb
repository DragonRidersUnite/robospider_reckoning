GAIN = 0.6

def play_sfx(args, key)
  if args.state.settings.sfx
    args.audio[key] = {
      input: "sounds/#{key}.wav",
      gain: GAIN,
    }
  end
end


def play_extended_sound(args, key, vol)
  if args.state.settings.sfx
    args.audio[key] ||= {
      input: "sounds/#{key}.wav",
      looping: true,
      gain: GAIN,
    }
    args.audio[key].gain = vol
    if vol > 0
      args.state.sounds ||= {}
      args.state.sounds[key] = true
    else
      args.audio[key] = false
    end
  end
end

def exterminate_sound(args, key)
  args.audio[key] = false
end

def exterminate_sounds(args)
  args.state.sounds.each do |key|
    args.audio[key[0]] = false
  end

  args.state.sounds = {}
end
