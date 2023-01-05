def tick_exp_chip(args, exp_chip)
  player = args.state.player
  if args.geometry.distance(exp_chip, player) <= player.exp_chip_magnetic_dist
    exp_chip.angle = args.geometry.angle_to(exp_chip, player)
    exp_chip.speed = player.speed + 1
  end

  if exp_chip.speed >= 1
    exp_chip.x_vel, exp_chip.y_vel = vel_from_angle(exp_chip.angle, exp_chip.speed)

    exp_chip.x += exp_chip.x_vel
    exp_chip.y += exp_chip.y_vel
    exp_chip.speed -= 1
  end
end
