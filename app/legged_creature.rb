# handles the logic for a legged creature. currently really only designed for the player character;
# could be expanded to be used for other creatures.
module LeggedCreature
  ALLOWED_LEG_OFFSET = 15
  class << self
    def create(args, x:, y:)
      p = {
        c_x: x,
        c_y: y,
        w: 40,
        h: 20,
        lin_vel: 0,
        ang_vel: 0,
        th: 0,
        path: :body,
        body_shift_x: x,
        body_shift_y: y,
        body_shift_th: 0,
        turret_th: 0,
        pid: {sums: {x: 0, y: 0, th: 0}}
      }

      args.outputs[:body].w = p.w
      args.outputs[:body].h = p.h
      args.outputs[:body].sprites << {
        x: 0,
        y: 0,
        w: p.w,
        h: p.h,
        tile_x: 0,
        tile_y: 0,
        tile_w: p.w,
        tile_h: p.h,
        path: "sprites/body.png"
      }

      p.legs = 6.times.map do |i|
        dir = i < 3 ? 1 : -1
        th = (i % 3 - 1) * (Math::PI * 0.7) / 3 + dir * Math::PI / 2
        rel_x = p.w * 0.8 * Math.cos(th)
        rel_y = p.w * 0.3 * Math.sin(th) + dir * 10
        c_x = p.c_x + Math.cos(th + p.th) * p.w * 0.8
        c_y = p.c_y + Math.sin(th + p.th) * p.w * 0.3 + dir * 10
        rel_anchor_x = -dir * (i % 3 - 1) * p.w / 3
        rel_anchor_y = dir * p.h / 2
        {
          c_x: c_x,
          c_y: c_y,
          w: 4,
          h: 4,
          lin_vel: 0,
          ang_vel: 0,
          th: 0,
          path: :leg,
          r: dir * 255,
          grounded: i.even?,
          rel_x: rel_x,
          rel_y: rel_y,
          rel_anchor_x: rel_anchor_x,
          rel_anchor_y: rel_anchor_y
        }
      end

      p
    end

    def dist(p1, p2)
      Math.sqrt((p1.x - p2.x) ** 2 + (p1.y - p2.y) ** 2)
    end

    def transform(x, y, th, rel_x, rel_y)
      x = x + Math.cos(th) * rel_x - Math.sin(th) * rel_y
      y = y + Math.sin(th) * rel_x + Math.cos(th) * rel_y

      [x, y]
    end

    def update(args, p, lin_vel_vec, shooting, rushing)
      dx = lin_vel_vec[0]
      dy = lin_vel_vec[1]
      desired_th = Math.atan2(dy, dx)
      dturret_th = 0
      dth = 0
      unless dx.zero? && dy.zero?
        dth = (desired_th - p.th + Math::PI) % (Math::PI * 2) - Math::PI
        dth = dth.clamp(-0.03, 0.03)
        unless shooting
          dturret_th = (desired_th - p.turret_th + Math::PI) % (Math::PI * 2) - Math::PI
        end
      end

      p.turret_th += dturret_th.clamp(-0.1, 0.1)

      p.c_x += dx
      p.c_y += dy
      p.th += -dth

      kp = 0.1
      kd = 0.00
      ki = 0.02
      err = p.c_x - p.body_shift_x
      p.pid.sums.x += 2 * err

      p.body_shift_x += kp * (p.c_x - p.body_shift_x) + kd * dx + ki * p.pid.sums.x

      err = p.c_y - p.body_shift_y
      p.pid.sums.y += 2 * err

      p.body_shift_y += kp * (p.c_y - p.body_shift_y) + kd * dy + ki * p.pid.sums.y

      kth = 0.07
      ki = 0.02
      err = p.th - p.body_shift_th
      p.pid.sums.th += 2 * err
      p.body_shift_th += kth * (p.th - p.body_shift_th) + ki * p.pid.sums.th

      if p.legs.select { |leg| leg.grounded }.any? do |leg|
          leg_dist = dist([leg.c_x, leg.c_y], [p.c_x, p.c_y])
          leg_th = Math.atan2(leg.c_y - p.c_y, leg.c_x - p.c_x)
          leg_th_dx = leg_dist * (Math.cos(leg_th) - Math.cos(leg_th + dth))
          leg_th_dy = leg_dist * (Math.sin(leg_th) - Math.sin(leg_th + dth))
          leg_d_x = dx + leg_th_dx
          leg_d_y = dy + leg_th_dy

          neut_x, neut_y = transform(p.c_x, p.c_y, p.th, leg.rel_x, leg.rel_y)
          dot_prod = leg_d_x * (neut_x - leg.c_x) + leg_d_y * (neut_y - leg.c_y)
          (dist([leg.c_x, leg.c_y], [neut_x, neut_y]) > ALLOWED_LEG_OFFSET) && (dot_prod > 0)
        end

        p.legs.each do |leg|
          leg.grounded = !leg.grounded
        end

        play_sfx(args, :pop)
      end

      p.legs.each do |leg|
        next if leg.grounded
        leg_dist = dist([leg.c_x, leg.c_y], [p.c_x, p.c_y])
        leg_th = Math.atan2(leg.c_y - p.c_y, leg.c_x - p.c_x)
        leg_th_dx = leg_dist * (Math.cos(leg_th) - Math.cos(leg_th + dth))
        leg_th_dy = leg_dist * (Math.sin(leg_th) - Math.sin(leg_th + dth))
        leg_d_x = dx + leg_th_dx
        leg_d_y = dy + leg_th_dy

        new_leg_c_x = leg.c_x + 2.0 * leg_d_x
        new_leg_c_y = leg.c_y + 2.0 * leg_d_y
        neut_x, neut_y = transform(p.c_x, p.c_y, p.th, leg.rel_x, leg.rel_y)

        return_val = 5
        if new_leg_c_x - neut_x > ALLOWED_LEG_OFFSET - return_val
          new_leg_c_x = neut_x + return_val
        elsif new_leg_c_x - neut_x < -(ALLOWED_LEG_OFFSET - return_val)
          new_leg_c_x = neut_x - return_val
        end

        if new_leg_c_y - neut_y > return_val
          new_leg_c_y = neut_y + return_val
        elsif new_leg_c_y - neut_y < -return_val
          new_leg_c_y = neut_y - return_val
        end

        leg.c_x = new_leg_c_x
        leg.c_y = new_leg_c_y
      end

      p.legs.each do |l|
        l.x = l.c_x - l.w / 2
        l.y = l.c_y - l.h / 2
        l.r = l.grounded ? 255 : 0
      end

      p.x = p.c_x - p.w / 2
      p.y = p.c_y - p.h / 2
      p.angle = (p.th * 180 / Math::PI) % 360 unless rushing
    end

    def render_legs(args, p, camera)
      leg_joints = p.legs.map do |leg|
        x, y = transform(
          p.body_shift_x - camera.x,
          p.body_shift_y - camera.y,
          p.body_shift_th,
          leg.rel_anchor_x,
          leg.rel_anchor_y
        )
        mid_joint_x = (x * 0.3 + (leg.c_x - camera.x) * 0.7)
        mid_joint_y = (y * 0.3 + (leg.c_y - camera.y) * 0.7)
        [
          {
            c_x: x,
            c_y: y,
            x: x - 2,
            y: y - 2,
            w: 4,
            h: 4,
            g: 255
          },
          {
            c_x: mid_joint_x,
            c_y: mid_joint_y,
            x: mid_joint_x - 2,
            y: mid_joint_y - 2,
            w: 4,
            h: 4,
            b: 255
          },
          leg
        ]
      end

      args.outputs.lines <<
        leg_joints.map do |leg|
          [
            {
              x: leg[0].c_x,
              y: leg[0].c_y,
              x2: leg[1].c_x,
              y2: leg[1].c_y,
              r: 221,
              g: 144,
              b: 22
            },
            {
              x: leg[1].c_x,
              y: leg[1].c_y,
              x2: leg[2].c_x - camera.x,
              y2: leg[2].c_y - camera.y,
              r: 113,
              g: 50,
              b: 94
            }
          ]
        end
    end

    def render(args, p, camera)
      args.outputs.sprites <<
        [
          p.merge(x: p.body_shift_x - p.w / 2 - camera.x, y: p.body_shift_y - p.h / 2 - camera.y, angle: p.body_shift_th * 180 / Math::PI)
        ]

      turret_c_x, turret_c_y = -p.w / 2 + 15, 0
      turret_th = p.turret_th
      turret_c_x, turret_c_y = transform(p.body_shift_x - camera.x, p.body_shift_y - camera.y, p.body_shift_th, turret_c_x, turret_c_y)

      args.outputs.sprites <<
        {
          x: turret_c_x - 6,
          y: turret_c_y - 6,
          w: 31,
          h: 33 - 21,
          r: 255,
          angle: turret_th * 180 / Math::PI,
          path: "sprites/body.png",
          tile_x: 0,
          tile_y: 21,
          tile_w: 31,
          tile_h: 33 - 21,
          angle_anchor_x: 0.2,
          angle_anchor_y: 0.5
        }

      render_legs(args, p, camera)
    end
  end
end
