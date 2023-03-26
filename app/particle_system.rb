module ParticleSystem
  class << self
    def create(effect, x:, y:, w: 1, h: 1, rate: 20, dir: 0, duration: nil)
      {
        # effect is a module that implements the Effect interface Eg: app/smoke_effect.rb
        effect: effect,
        rate: rate,
        x: x,
        y: y,
        w: w,
        h: h,
        dir: dir,
        duration: duration,
        ticks_since_last_emission: 0,
        particles: []
      }
    end

    def tick(args, sys)
      sys.duration -= 1 if sys.duration

      sys.particles.each { sys.effect.tick(_1, sys) }

      if emit?(sys)
        # rate: 5 => 12 pps; 0.2 => 300 pps. If ticks_per_emision < 1, multiple particles will be emitted in a single tick
        ticks_per_emission = 60.fdiv(sys.rate)

        # count ticks until we reach a tick where we should emit a particle.
        sys.ticks_since_last_emission += 1
        particles_to_emit = (sys.ticks_since_last_emission / ticks_per_emission).floor

        if particles_to_emit > 0
          particles_to_emit.times { |i| sys.particles << sys.effect.emit_particle(sys) }
          sys.ticks_since_last_emission = 0
        end
      end
    end

    def emit?(sys)
      true if sys.duration.nil?
      sys.duration > 0
    end

    def dead?(sys)
      sys.duration <= 0 && sys.particles.empty?
    end

    def destroy(sys)
      sys.particles = []
    end
  end
end
