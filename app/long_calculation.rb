module LongCalculation
  class << self
    def define
      fiber = Fiber.new do |steps|
        Fiber.current.steps = steps
        result = yield
        Fiber.yield result
      end
      add_additional_methods fiber
      fiber
    end

    def finish_step
      Fiber.current.steps -= 1
      Fiber.current.steps = Fiber.yield if Fiber.current.steps.zero?
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
    end
  end
end
