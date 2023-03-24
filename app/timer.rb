module Timer
  class << self
    def every(period)
      {period: period, elapsed: 0, active: true}
    end

    def tick(timer)
      timer[:elapsed] += 1
      timer[:elapsed] = 0 if timer[:elapsed] >= timer[:period]
      timer[:active] = timer[:elapsed] == 0
    end

    def update_period(timer, period)
      timer[:period] = period
    end

    def active?(timer)
      timer[:active]
    end
  end
end
