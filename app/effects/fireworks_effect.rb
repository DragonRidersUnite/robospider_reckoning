
module FireworksEffect
  DISSOLVE_SPEED = 2
  class << self
    def emit_particle(sys)
      {
        x: sys.x + rand(20), 
        y: sys.y + rand(20), 
        w: 1, 
        h: 1, 
        angle: 0, 
        dir: rand(360),
        r: rand(255), g: rand(255), b: rand(255), a: 150,
        path: :pixel,
        blendmode_enum: 2
      }
    end

    def tick(particle, sys)
      sys.particles.delete particle if dead_particle? particle

      particle.x += 1.5 * (Math.cos(particle.dir * DEG2RAD) - 1) / DISSOLVE_SPEED
      particle.y += 1.5 * (Math.sin(particle.dir * DEG2RAD) - 1) / DISSOLVE_SPEED
      particle.angle += (particle.dir < 180) ? -0.5 : 0.5
      particle.h += 2 / DISSOLVE_SPEED
      particle.w += 2 / DISSOLVE_SPEED
      particle.a -= DISSOLVE_SPEED
    end

    def dead_particle?(particle)
      particle.a <= 0
    end
  end
end
