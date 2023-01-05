# Exquisite Corps

**A collaborative jam of chaos**

Built with DragonRuby Game Toolkit v4.0 Standard Edition.

## Controls

- Move: WASD / Arrow Keys / Gamepad
- Select & Fire: J / Z / Space / Gamepad A button

## Premise

Inspired by the exquisite corpse exercise that artists do, what if we made a game where each person worked on it for a week and then passed it to the next person?

Any member of the DragonRuby community can sign up, and the game will be done when there's no one left to go!

The spirit of this project is to experiment, have fun, and be less precious about what we make. Much like improv, there are no rules other than to say "yes, and" to those who went before you. It's okay to rewrite code, change things, add things, but don't just wholesale tear out what other people did.

Have fun! See you on the other side.

[Discord Thread](https://discord.com/channels/608064116111966245/1051849160627847219)

## Developing

The engine files are not included in this source repository so that people can use whatever operating system they want. Also, if we open source it when it's done, it's easier to not have to deal with that.

1. Unzip the DragonRuby Game Toolkit engine zip
2. Delete the `mygame` directory
3. Clone the repository into the DRGTK engine folder with the folder name `mygame`: `git clone git@github.com:DragonRidersUnite/exquisite_corps.git mygame`
4. Start DragonRuby, and make it awesome!

### Where to Start

When your week is beginning, add your name to the `CREDITS` array. It's a shuffled list of everyone who worked on the game.

### On the Code Architecture

The code is intentionally structured to make use of functions and `args.state` without any classes. A functional-ish approach. This follows in the spirit of DRGTK's docs.

### Keyboard Shortcuts

There following debug-only shortcuts can be used to help make developing easier:

- <kbd>i</kbd> -- reload the sprites from disk
- <kbd>r</kbd> -- reset the game
- <kbd>0</kbd> -- render debug details
- <kbd>1</kbd> -- level up player
- <kbd>2</kbd> -- toggle player invincibility

### Tests

Tests for methods live in `app/tests.rb`. Run the tests with from within your engine dir with:

``` console
./dragonruby mygame --eval mygame/app/tests.rb --no-tick --exit-on-fail
```

or just use `./run_tests`
