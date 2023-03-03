module Fireworks
  DEG2RAD = Math::PI / 180
  
  class << self
    def create
      []
    end

    def ignite(x, y, rate, counter, reducer)
      {
        x: x,
        y: y,
        rate: rate,
        particles: [],
        ticks_since_last_emission: 0,
        counter: counter,
        reducer: reducer,
      }
    end
  
    def update fw
      fw.counter -= 1
      update_particles fw
      if emit? fw
        # rate: 5 => 12 pps; 0.2 => 300 pps. If ticks_per_emision < 1, multiple particles will be emitted in a single tick
        ticks_per_emission = 60.fdiv(fw.rate)
    
        # count ticks until we reach a tick where we should emit a particle.
        fw.ticks_since_last_emission += 1
        particles_to_emit = (fw.ticks_since_last_emission / ticks_per_emission).floor
    
        if particles_to_emit > 0
          particles_to_emit.times { |i| fw.particles << emit(fw) }
          fw.ticks_since_last_emission = 0
        end
      end
    end
  
    def emit? fw
      true if fw.counter.nil?
      fw.counter > 0
    end
  
    def dead? fw
      fw.counter <= 0 && fw.particles.empty?
    end
  
    def update_particles fw
      fw.particles.reject! {|p| p[:a]<=0}
    
      fw.particles.each do |p|
        p.x += (Math.cos(p.dir * DEG2RAD) - 1) / fw.reducer
        p.y += (Math.sin(p.dir * DEG2RAD) - 1) / fw.reducer
        p.angle += p.dir < 180 ? -0.5 : 0.5
        p.h += (2)/fw.reducer
        p.w += (2)/fw.reducer
        p.a -= 1
      end
    end
  
    def render(sprites, fw)
      sprites << fw.particles
    end
  
    def emit fw
      {
        x: (fw.x) + rand(20), y: (fw.y) + rand(20), w: 1, h: 1, angle: 0, dir: rand(360),
        r: rand(255), g: rand(255), b: rand(255), a: 150, 
        path: :pixel, blendmode_enum: 2,
      }
    end
  
    def extinguish(fireworks)
      fireworks.length.times { |i| fireworks.pop }
    end

    def launch(fireworks, num)
      num.times {|fw| fireworks << ignite(rand(1200)+40, rand(700)+10, 20, 50, [5,10,10,15][rand(4)])}
    end

    def tick(args, fireworks)
      sprites = args.outputs.sprites
      fireworks.each do |fw|
        update(fw)
        fireworks.delete(fw) if dead? fw
        render(sprites, fw)
      end
    end
  end
end
