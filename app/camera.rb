module Camera
  class << self
    def build
      { x: 0, y: 0, w: 1280, h: 720 }
    end

    # Follows the target object with the camera
    def follow(camera, target:, bounds:)
      camera[:x] = (target.x - (camera.w / 2) + (target.w / 2)).clamp(0, bounds.right - camera.w)
      camera[:y] = (target.y - (camera.h / 2) + (target.h / 2)).clamp(0, bounds.top - camera.h)
    end

    # Returns a copy of the object with its x and y coordinates translated
    def translate(camera, object)
      return object.map { |o| translate(camera, o) } if object.is_a?(Array)

      object.merge(
        x: object.x - camera.x,
        y: object.y - camera.y
      )
    end
  end
end
