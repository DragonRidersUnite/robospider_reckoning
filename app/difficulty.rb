# Handles the logic of returning the value bassed on difficulty setting.
# The setting consist of three parameters:  :easy, :normal, :hard.
# The "values_array" argument is expected to be an array of three values,
# each corresponding to the different difficulty levels. The method will
# return the value corresponding to the current difficulty setting.

module Difficulty
  class << self
    def based(args, values_array)
      values_array[DIFFICULTY.index(args.state.settings.difficulty)]
    end
  end
end
