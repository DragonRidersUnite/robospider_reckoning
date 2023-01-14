# A scene represents a discreet state of gameplay. Things like the main menu,
# game over screen, and gameplay.
#
# Define a new scene by adding one to `app/scenes/` and defining a
# `Scene.tick_SCENE_NAME` class method.
#
# The main `#tick` of the game handles delegating to the current scene based on
# the `args.state.scene` value, which is a symbol of the current scene, ex:
# `:gameplay`
module Scene
  class << self
    # Change the current scene, and optionally reset the scene that's begin
    # changed to so any data is cleared out
    # ex:
    #   Scene.switch(args, :gameplay)
    def switch(args, scene, reset: false, return_to: nil)
      args.state.scene_to_return_to = return_to if return_to

      if scene == :back && args.state.scene_to_return_to
        scene = args.state.scene_to_return_to
        args.state.scene_to_return_to = nil
      end

      Scene.send("reset_#{scene}", args) if reset && Scene.respond_to?("reset_#{scene}")

      args.state.scene = scene
    end
  end
end
