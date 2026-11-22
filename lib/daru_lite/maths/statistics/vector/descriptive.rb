module DaruLite
  module Maths
    module Statistics
      module Vector
        # Central tendency, counts and frequencies.
        module Descriptive
          def mean
            @data.mean
          end

          def sum
            @data.sum
          end

          def product
            @data.product
          end

          def range
            max - min
          end

          def median
            @data.respond_to?(:median) ? @data.median : percentile(50)
          end

          def mode
            mode = frequencies.to_h.select { |_, v| v == frequencies.max }.keys
            mode.size > 1 ? DaruLite::Vector.new(mode) : mode.first
          end

          # Create a summary of count, mean, standard deviation, min and max of
          # the vector in one shot.
          #
          # == Arguments
          #
          # +methods+ - An array with aggregation methods specified as symbols to
          # be applied to vectors. Default is [:count, :mean, :std, :max,
          # :min]. Methods will be applied in the specified order.
          def describe(methods = nil)
            methods ||= %i[count mean std min max]
            description = methods.map { |m| send(m) }
            DaruLite::Vector.new(description, index: methods, name: :statistics)
          end

          def median_absolute_deviation
            m = median
            recode { |val| (val - m).abs }.median
          end

          alias mad median_absolute_deviation

          def standard_error
            standard_deviation_sample / Math.sqrt(size - count_values(*DaruLite::MISSING_VALUES))
          end

          def sum_of_squared_deviation
            (
              reject_values(*DaruLite::MISSING_VALUES).data.inject(0) { |a, x| (x**2) + a } -
              (sum**2).quo(size - count_values(*DaruLite::MISSING_VALUES)).to_f
            ).to_f
          end

          # Retrieve unique values of non-nil data
          def factors
            reject_values(*DaruLite::MISSING_VALUES).uniq.reset_index!
          end

          def frequencies
            DaruLite::Vector.new(
              @data.each_with_object(Hash.new(0)) do |element, hash|
                hash[element] += 1 unless element.nil?
              end
            )
          end

          def proportions
            len = size - count_values(*DaruLite::MISSING_VALUES)
            frequencies.to_h.transform_values do |count|
              count / len.to_f
            end
          end

          def ranked
            sum = 0
            r = frequencies.to_h.sort.each_with_object({}) do |(el, count), memo|
              memo[el] = ((sum + 1) + (sum + count)).quo(2)
              sum += count
            end

            recode { |e| r[e] }
          end

          def coefficient_of_variation
            standard_deviation_sample / mean
          end

          # Retrieves number of cases which comply condition. If block given,
          # retrieves number of instances where block returns true. If other
          # values given, retrieves the frequency for this value. If no value
          # given, counts the number of non-nil elements in the Vector.
          def count(value = false, &block)
            if block
              @data.count(&block)
            elsif value
              count { |val| val == value }
            else
              size - indexes(*DaruLite::MISSING_VALUES).size
            end
          end

          # Count number of occurrences of each value in the Vector
          def value_counts
            DaruLite::Vector.new(@data.tally)
          end

          def proportion(value = 1)
            if include_with_nan?(DaruLite::MISSING_VALUES, value)
              raise ArgumentError, 'Cannot calculate the proportion of a missing value'
            end

            present = size - count_values(*DaruLite::MISSING_VALUES)
            raise ArgumentError, 'Cannot calculate a proportion without any non-missing value' if present.zero?

            count { |element| element == value }.quo(present).to_f
          end

          alias cov coefficient_of_variation
          alias se standard_error
        end
      end
    end
  end
end
