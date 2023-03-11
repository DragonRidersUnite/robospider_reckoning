module SmokeEffect
  DISSOLVE_SPEED = 2
  class << self
    def emit_particle(sys)
      color = random(150,255)
      puts "dir: #{sys.dir + rand(180) - 90}"
      {
        x: sys.x, 
        y: sys.y, 
        w: 8, 
        h: 8, 
        angle: 0, 
        dir: sys.dir + rand(180) - 90,
        r: color, g: color, b: color, a: 150,
        path: Sprite::SPRITES[:bullet],
        blendmode_enum: 2
      }
    end

    def tick(particle, sys)
      sys.particles.delete particle if dead_particle? particle

      particle.x += (Math.cos(particle.dir * DEG2RAD)) *1.2
      particle.y += (Math.sin(particle.dir * DEG2RAD)) *1.2
      particle.angle += [-5, 5].sample
      particle.h -= 0.1
      particle.w -= 0.1
      particle.a -= 5
    end

    def dead_particle?(particle)
      particle.a <= 0
    end
  end
end
