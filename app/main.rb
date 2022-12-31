FPS = 60
ALIGN_LEFT = 0
ALIGN_CENTER = 1
ALIGN_RIGHT = 2
BLEND_NONE = 0
BLEND_ALPHA = 1
BLEND_ADDITIVE = 2
BLEND_MODULO = 3
BLEND_MULTIPLY = 4

TRUE_BLACK = { r: 0, g: 0, b: 0 }
WHITE = { r: 255, g: 255, b: 255 }

# Access in code with `SPATHS[:my_sprite]`
# Replace with your sprites!
SPATHS = {
  my_sprite: "sprites/my_sprite.png",
}

# Code that only gets run once on game start
def init(args)
end

def tick(args)
  init(args) if args.state.tick_count == 0

  args.outputs.background_color = TRUE_BLACK.values

  args.state.player ||= {
    x: args.grid.w / 2,
    y: args.grid.h / 2,
    w: 32,
    h: 32,
    speed: 6,
  }.merge(WHITE)

  tick_player(args, args.state.player)

  args.outputs.solids << args.state.player

  debug_tick(args)
end

def tick_player(args, player)
  if args.inputs.down
    player.y -= player.speed
  end

  if args.inputs.up
    player.y += player.speed
  end

  if args.inputs.left
    player.x -= player.speed
  end

  if args.inputs.right
    player.x += player.speed
  end
end

# The version of your game defined in `metadata/game_metadata.txt`
def version
  $gtk.args.cvars['game_metadata.version'].value
end

def debug?
  @debug ||= !$gtk.production
end

def debug_tick(args)
  return unless debug?

  args.outputs.debug << [args.grid.w - 12, args.grid.h, "#{args.gtk.current_framerate.round}", 0, 1, *WHITE.values].label

  if args.inputs.keyboard.key_down.i
    SPATHS.each { |_, v| args.gtk.reset_sprite(v) }
    args.gtk.notify!("Sprites reloaded")
  end

  if args.inputs.keyboard.key_down.r
    $gtk.reset
  end
end
