module DaruLite
  module Maths
    module Statistics
      module Vector
        # Random samples of the non-missing values.
        module Sampling
          # Returns an random sample of size n, with replacement,
          # only with non-nil data.
          #
          # In all the trails, every item have the same probability
          # of been selected.
          def sample_with_replacement(sample = 1)
            if @data.respond_to? :sample_with_replacement
              @data.sample_with_replacement sample
            else
              valid = indexes(*DaruLite::MISSING_VALUES).empty? ? self : reject_values(*DaruLite::MISSING_VALUES)
              vds = valid.size
              (0...sample).collect { valid[rand(vds)] }
            end
          end

          # Returns an random sample of size n, without replacement,
          # only with valid data.
          #
          # Every element could only be selected once.
          #
          # A sample of the same size of the vector is the vector itself.
          def sample_without_replacement(sample = 1)
            if @data.respond_to? :sample_without_replacement
              @data.sample_without_replacement sample
            else
              raw_sample_without_replacement(sample)
            end
          end

          private

          def raw_sample_without_replacement(sample)
            valid = indexes(*DaruLite::MISSING_VALUES).empty? ? self : reject_values(*DaruLite::MISSING_VALUES)
            raise ArgumentError, "Sample size couldn't be greater than n" if
              sample > valid.size

            out  = []
            size = valid.size
            while out.size < sample
              value = rand(size)
              out.push(value) unless out.include?(value)
            end

            out.collect { |i| valid[i] }
          end
        end
      end
    end
  end
end
