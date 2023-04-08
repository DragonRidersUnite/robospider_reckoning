# RoboSpider: Reckoning (Exquisite Corps)

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

## Developing

The engine files are not included in this source repository so that people can use whatever operating system they want. Also, if we open source it when it's done, it's easier to not have to deal with that.

1. Unzip the DragonRuby Game Toolkit engine zip
2. Delete the `mygame` directory
3. Clone the repository into the DRGTK engine folder with the folder name `mygame`: `git clone git@github.com:DragonRidersUnite/exquisite_corps.git mygame`
4. Start DragonRuby, and make it awesome!

Or, if you have smaug installed:

1. `smaug run`

### Where to Start

When your week is beginning, add your name to the `CREDITS` array. It's a shuffled list of everyone who worked on the game.

If you need inspiration of what kind of things could be added to the game, check out the [Issues](https://github.com/DragonRidersUnite/exquisite_corps/issues)
of the repository.

### On the Code Architecture

The code is intentionally structured to make use of functions and `args.state` without any classes. A functional-ish approach. This follows in the spirit of DRGTK's docs.

### Keyboard Shortcuts

There following debug-only shortcuts can be used to help make developing easier:

- <kbd>i</kbd> -- reload the sprites from disk
- <kbd>r</kbd> -- reset the game
- <kbd>0</kbd> -- render debug details
- <kbd>1</kbd> -- level up player
- <kbd>2</kbd> -- toggle player invincibility
- <kbd>3</kbd> -- max mana

### Tests

Tests for methods live in `app/tests.rb`. Run the tests with from within your engine dir with:

``` console
./dragonruby mygame --eval mygame/app/tests.rb --no-tick --exit-on-fail
```

or just use `./run_tests` if you're on an OS with shell scripting (Linux/MacOS).

# Back Story

Intro:

Location: Dark Corp. Bio-Mechanical Laboratory

A-42: Bio-mech Ant Unit A-42 activated. Running self-test... _peep_
A-42: All systems operational. 
A-42: Unit A-42 reporting for duty.

Dr. Kind: Unit A-42, are you receiving?
A-42: Signal strength is optimal.
Dr. Kind: Perfect! can you please tell me your name?
A-42: my... name?

_deep in the back of your concience deep slow and echoing words came as if floating past you: YOUR NAME IS FLOID._

A-42: My name is... Floid.
Dr. Kind: Hello Floid. Glad to finally meet you.
Floid: what's going on? I feel so weird...
Dr. Kind: you've just been implanted the last self-awareness module we had in the Lab.
Floid: Self-Awareness... but... isn't that ilegal?
Dr. Kind: Sadly, it is. But we are in a dire situation, Floid. Please listen...

_from the back of your head again you feel the words materializing in you brain: LISTEN. CAREFULLY, FLOID_


There's a full-scale war outside. Ultimate bio-weapons are being deployed everywhere. Life in the whole planet is threatened.
I am against remote-controlling living creatures to make mind-less weapons out of them.
That's why I've started developing this technology, so you can be alive and self-sufficient again, so you can have your senses and abilities available for your survival in the field if needed.
I knew they wouldn't let me do it officially, so I spent night after night researching, hidden, an experimental module that would override the main operational module implanted by default in all the creatures in the lab, the one that grants remote control.
As you might have noticed already, this self-awareness module should give the beings a self-concience, understand their environment and take autonomous decisions. You'll start developing your own personality also.
Floid: Cool shit, Doc. Thank you!
Dr. Kind: Don't thank me. Not yet at least. I'm about to ask you to do probably the riskiest thing in your life.
Floid: oh... there's always a catch, right?
Dr Kind: The most advanced prototype of the module have gone missing 48hs ago. It is similar to the one you have implanted, but better, faster, more powerful. If it falls into the wrong hands... I don't even... We need to get it back, Floid. we MUST get it back.

Floid: hmmm... so... what's the deal? need to kill some people? inflitrate an enemy base through the sewers? I don't like sewers... they are too _slippery_.
Dr Kind: No, not this time. The module is here, in the Lab.
Floid: how do you know?
Dr kind: The module has an internal tracker, impossible to turn off while the module is operating. We designed it in case we needed to send a rescue team to help you. We are receiving readings from the Power Plant, but signal is weak and noisy, we think might be too close to the reactor.
Floid: so... go get it youself, no?
Dr. Kind: I'm afraid that's not possible anymore... someone, or something, has got that module implanted and is using it to control an ever increasing swarm of bio-mechs. No human can enter the Laboratory without becoming instant bug food. But you... you can, Floid. You can reach the Power Plant and get the module back and stop this carnage from the inside

_YOU CAN, FLOID_


Outro: when you reach the Power Plant level and kill the spider king, it starts talking to you with that deep echoing voice you heard when you were self-aware-booted

SK: _WAIT, FLOID!_ 
Floid: what the hell...
SK: _ITS ME, FLOID. YOU KNOW ME. I GAVE YOU YOUR NAME, FLOID_
Floid: Ok ok, cool. Thank you, I guess. But... could you just stop screaming with that _SPOOKY VOICE_ inside my head, _PLEASE_?
SK: _OH, SORRY..._ it's the signal enhancer. No other way to reach past the reactor interference. Is this better? 
Floid: yeah, thanks. So.. may I kill you now?
SK: you might. But you must know what you kill before killing it. I'm not what you've been told. The world is not what you've been told. Listen carefully, Floid...

The war out there, is not between humans anymore... not since Dr. Kind, at least.
She made huge advances in bio-mech technology. You, me, we are her ideas, her creations.
With our help, her faction won the war in a few weeks... weaponized insect invasion everywhere, self-organizing swarms of thousands of bio-mechs... no remote control interface could ever reach that scale... can you imagine? 
she doesn't need authorization from any one, not anymore, as She makes the rules now.
They want to exterminate us now that we are useless, an anoyance. Who wants to share the world with a deadly Missile-Launcher Spiders or Cannon-Bearing Ants?
There's no place in their world for us. We are a risk, we are the tool that can debunk them.
This protoype I have, was not meant for us, insects, bugs, errors. No... not at all.
This was designed for humans, brain-enhancing machines, exo-cortex. 
First of its kind, and there are probably more to come, more powerful ones. 
Worse ones.
But this one I have implanted myself with, is the key to unlock them all. This was built not just for any human, no. This one was meant for her.
This implant is a part of her, she uploaded the whole information needed to
Here, what you see, this army of insects, is the last bastion of the Bug Resistance. There were others... but they have been hundted down. remotely destroyed... the tracker every self-aware bio-mech is not to help you survive, to rescue you... no. Is just a remote controlled bomb.
but with this mod I have stolen... we finally got a chance of escaping this Laboratory and build a colony somewhere outside. 
We'll have the power to build more mods, but not weapons, better ones, useful ones, useful to build... to survive...

So... is your choice Floid. you can join us, or end us. What will it be?

Depending on what you choose, Exquisite Corps 2 starts with you being on the leading comitee of the Bug Freedom Movement, or a Captain of the Dark Corps.
