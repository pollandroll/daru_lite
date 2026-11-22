require 'daru_lite/maths/statistics/vector/descriptive'
require 'daru_lite/maths/statistics/vector/extrema'
require 'daru_lite/maths/statistics/vector/dispersion'
require 'daru_lite/maths/statistics/vector/percentile'
require 'daru_lite/maths/statistics/vector/normalization'
require 'daru_lite/maths/statistics/vector/sampling'
require 'daru_lite/maths/statistics/vector/time_series'

module DaruLite
  module Maths
    # Encapsulates statistics methods for vectors. Most basic stuff like mean, etc.
    # is done inside the wrapper, so that native methods can be used for most of
    # the computationally intensive tasks.
    module Statistics
      module Vector
        include Descriptive
        include Extrema
        include Dispersion
        include Percentile
        include Normalization
        include Sampling
        include TimeSeries

        private

        def must_be_numeric!
          numeric? or raise TypeError, 'Vector must be numeric'
        end
      end
    end
  end
end
