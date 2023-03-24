module Fireworks
  class << self
    def create
      []
    end

    def tick(fireworks, args)
      fireworks.reject! { ParticleSystem.dead?(_1) }
      fireworks.each { ParticleSystem.tick(args, _1) }
      args.outputs.sprites << fireworks.flat_map { _1.particles }
    end

    def launch(fireworks, args)
      if args.tick_count.mod_zero?(4)
        fireworks <<
          ParticleSystem.create(
            FireworksEffect,
            x: rand(1200) + 40,
            y: rand(700) + 10,
            w: 20,
            h: 20,
            rate: random(30, 50),
            duration: random(20, 50)
          )
      end
    end
  end
end
