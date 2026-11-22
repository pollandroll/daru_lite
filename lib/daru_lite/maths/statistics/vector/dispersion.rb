module DaruLite
  module Maths
    module Statistics
      module Vector
        # Variance, covariance, standard deviation and shape of the distribution.
        module Dispersion
          # Sample variance with denominator (N-1)
          def variance_sample(m = nil)
            m ||= mean
            if @data.respond_to? :variance_sample
              @data.variance_sample m
            else
              sum_of_squares(m).quo(size - count_values(*DaruLite::MISSING_VALUES) - 1)
            end
          end

          # Population variance with denominator (N)
          def variance_population(m = nil)
            m ||= mean
            if @data.respond_to? :variance_population
              @data.variance_population m
            else
              sum_of_squares(m).quo(size - count_values(*DaruLite::MISSING_VALUES)).to_f
            end
          end

          # Sample covariance with denominator (N-1)
          def covariance_sample(other)
            size == other.size or raise ArgumentError, 'size of both the vectors must be equal'
            covariance_sum(other) / (size - count_values(*DaruLite::MISSING_VALUES) - 1)
          end

          # Population covariance with denominator (N)
          def covariance_population(other)
            size == other.size or raise ArgumentError, 'size of both the vectors must be equal'
            covariance_sum(other) / (size - count_values(*DaruLite::MISSING_VALUES))
          end

          def sum_of_squares(m = nil)
            m ||= mean
            reject_values(*DaruLite::MISSING_VALUES).data.inject(0) do |memo, val|
              memo + ((val - m)**2)
            end
          end

          def standard_deviation_population(m = nil)
            m ||= mean
            if @data.respond_to? :standard_deviation_population
              @data.standard_deviation_population(m)
            else
              Math.sqrt(variance_population(m))
            end
          end

          def standard_deviation_sample(m = nil)
            m ||= mean
            if @data.respond_to? :standard_deviation_sample
              @data.standard_deviation_sample m
            else
              Math.sqrt(variance_sample(m))
            end
          end

          # Calculate skewness using (sigma(xi - mean)^3)/((N)*std_dev_sample^3)
          def skew(m = nil)
            if @data.respond_to? :skew
              @data.skew
            else
              m ||= mean
              th  = reject_values(*DaruLite::MISSING_VALUES).data.inject(0) { |memo, val| memo + ((val - m)**3) }
              th.quo((size - indexes(*DaruLite::MISSING_VALUES).size) * (standard_deviation_sample(m)**3))
            end
          end

          def kurtosis(m = nil)
            if @data.respond_to? :kurtosis
              @data.kurtosis
            else
              m ||= mean
              fo  = reject_values(*DaruLite::MISSING_VALUES).data.inject(0) { |a, x| a + ((x - m)**4) }
              fo.quo((size - indexes(*DaruLite::MISSING_VALUES).size) * (standard_deviation_sample(m)**4)) - 3
            end
          end

          def average_deviation_population(m = nil)
            must_be_numeric!
            m ||= mean
            reject_values(*DaruLite::MISSING_VALUES).data.inject(0) do |memo, val|
              (val - m).abs + memo
            end.quo(size - count_values(*DaruLite::MISSING_VALUES))
          end

          alias sdp standard_deviation_population
          alias sds standard_deviation_sample
          alias std sds
          alias adp average_deviation_population
          alias variance variance_sample
          alias covariance covariance_sample
          alias sd standard_deviation_sample
          alias ss sum_of_squares

          private

          def covariance_sum(other)
            self_mean = mean
            other_mean = other.mean
            @data
              .zip(other.data).inject(0) do |res, (d, o)|
                res + if !d || !o
                        0
                      else
                        (d - self_mean) * (o - other_mean)
                      end
              end
          end
        end
      end
    end
  end
end
