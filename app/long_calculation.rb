module LongCalculation
  class << self
    def define
      if inside_calculation?
        # Don't create a new fiber just execute the block
        result = yield
        # Create a fake fiber-like object which responds to calculate_in_one_step
        # and returns the result of the block
        fake_fiber = Object.new
        fake_fiber.define_singleton_method(:calculate_in_one_step) do
          result
        end

        fake_fiber
      else
        fiber = Fiber.new do |steps|
          Fiber.current.steps = steps || 1
          result = yield
          Fiber.yield result
        end

        add_additional_methods(fiber)
        fiber
      end
    end

    def finish_step
      return unless inside_calculation?

      Fiber.current.steps -= 1
      Fiber.current.steps = (Fiber.yield() || 1) if Fiber.current.steps.zero?
    end

    def inside_calculation?
      Fiber.current.respond_to?(:steps)
    end

    private

    def add_additional_methods(fiber)
      state = {}
      fiber.define_singleton_method(:steps) do
        state.steps
      end

      fiber.define_singleton_method(:steps=) do |steps|
        state.steps = steps
      end

      fiber.define_singleton_method(:calculate_in_one_step) do
        result = resume(1000) while result.nil?
        result
      end

      fiber.define_singleton_method(:run_for_ms) do |ms|
        start_time = Time.now.to_f
        result = resume while result.nil? && (Time.now.to_f - start_time) * 1000 < ms
        result
      end
    end
  end
end
