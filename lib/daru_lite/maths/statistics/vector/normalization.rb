module DaruLite
  module Maths
    module Statistics
      module Vector
        # Centering, standardizing and other value transformations.
        module Normalization
          # Dichotomize the vector with 0 and 1, based on lowest value.
          # If parameter is defined, this value and lower will be 0
          # and higher, 1.
          def dichotomize(low = nil)
            low ||= factors.min

            recode do |x|
              if x.nil?
                nil
              elsif x > low
                1
              else
                0
              end
            end
          end

          # Center data by subtracting the mean from each non-nil value.
          def center
            self - mean
          end

          # Standardize data.
          #
          # == Arguments
          #
          # * use_population - Pass as *true* if you want to use population
          # standard deviation instead of sample standard deviation.
          def standardize(use_population = false)
            m ||= mean
            sd = use_population ? sdp : sds
            return DaruLite::Vector.new([nil] * size) if m.nil? || sd.nil? || sd.zero?

            vector_standardized_compute m, sd
          end

          # simplecov:disable
          def box_cox_transformation(lambda) # :nodoc:
            must_be_numeric!

            recode do |x|
              unless x.nil?
                if lambda.zero?
                  Math.log(x)
                else
                  ((x**lambda) - 1).quo(lambda)
                end
              end
            end
          end
          # simplecov:enable

          # Replace each non-nil value in the vector with its percentile.
          def vector_percentile
            c = size - indexes(*DaruLite::MISSING_VALUES).size
            ranked.recode! { |i| i.nil? ? nil : (i.quo(c) * 100).to_f }
          end

          def vector_standardized_compute(m, sd)
            if @data.respond_to? :vector_standardized_compute
              @data.vector_standardized_compute(m, sd)
            else
              DaruLite::Vector.new @data.collect { |x| x.nil? ? nil : (x.to_f - m).quo(sd) },
                                   index: index, name: name, dtype: dtype
            end
          end

          def vector_centered_compute(m)
            if @data.respond_to? :vector_centered_compute
              @data.vector_centered_compute(m)
            else
              DaruLite::Vector.new @data.collect { |x| x.nil? ? nil : x.to_f - m },
                                   index: index, name: name, dtype: dtype
            end
          end
        end
      end
    end
  end
end
