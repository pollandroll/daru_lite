module DaruLite
  module Maths
    module Statistics
      module Vector
        # Percentiles and their interpolation strategies.
        module Percentile
          # Returns the value of the percentile q
          #
          # Accepts an optional second argument specifying the strategy to interpolate
          # when the requested percentile lies between two data points a and b
          # Valid strategies are:
          # * :midpoint (Default): (a + b) / 2
          # * :linear : a + (b - a) * d where d is the decimal part of the index between a and b.
          # == References
          #
          # This is the NIST recommended method (http://en.wikipedia.org/wiki/Percentile#NIST_method)
          def percentile(q, strategy = :midpoint)
            case strategy
            when :midpoint
              midpoint_percentile(q)
            when :linear
              linear_percentile(q)
            else
              raise ArgumentError, "Unknown strategy #{strategy}"
            end
          end

          alias percentil percentile

          private

          def midpoint_percentile(q)
            raise ArgumentError, "q must be between 0 and 100, got #{q}" unless q.between?(0, 100)

            sorted = reject_values(*DaruLite::MISSING_VALUES).to_a.sort

            v = ((size - count_values(*DaruLite::MISSING_VALUES)) * q).quo(100)
            if v.to_i == v
              (sorted[(v - 0.5).to_i].to_f + sorted[[(v + 0.5).to_i, sorted.size - 1].min]).quo(2)
            else
              sorted[v.to_i]
            end
          end

          def linear_percentile(q)
            sorted = reject_values(*DaruLite::MISSING_VALUES).to_a.sort
            index = (q / 100.0) * ((size - count_values(*DaruLite::MISSING_VALUES)) + 1)

            k = index.truncate
            d = index % 1

            if k.zero?
              sorted[0]
            elsif k >= sorted.size
              sorted[-1]
            else
              sorted[k - 1] + (d * (sorted[k] - sorted[k - 1]))
            end
          end
        end
      end
    end
  end
end
