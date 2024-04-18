module DaruLite
  class Vector
    module Missable
      extend Gem::Deprecate

      # Reports whether missing data is present in the Vector.
      def has_missing_data? # rubocop:disable Naming/PredicateName
        !indexes(*DaruLite::MISSING_VALUES).empty?
      end
      alias flawed? has_missing_data?
      deprecate :has_missing_data?, :include_values?, 2016, 10
      deprecate :flawed?, :include_values?, 2016, 10

      # Replace all nils in the vector with the value passed as an argument. Destructive.
      # See #replace_nils for non-destructive version
      #
      # == Arguments
      #
      # * +replacement+ - The value which should replace all nils
      def replace_nils!(replacement)
        indexes(*DaruLite::MISSING_VALUES).each do |idx|
          self[idx] = replacement
        end

        self
      end

      # Rolling fillna
      # replace all Float::NAN and NIL values with the preceeding or following value
      #
      # @param direction [Symbol] (:forward, :backward) whether replacement value is preceeding or following
      #
      # @example
      #  dv = DaruLite::Vector.new([1, 2, 1, 4, nil, Float::NAN, 3, nil, Float::NAN])
      #
      #   2.3.3 :068 > dv.rolling_fillna(:forward)
      #   => #<DaruLite::Vector(9)>
      #   0   1
      #   1   2
      #   2   1
      #   3   4
      #   4   4
      #   5   4
      #   6   3
      #   7   3
      #   8   3
      #
      def rolling_fillna!(direction = :forward)
        enum = direction == :forward ? index : index.reverse_each
        last_valid_value = 0
        enum.each do |idx|
          if valid_value?(self[idx])
            last_valid_value = self[idx]
          else
            self[idx] = last_valid_value
          end
        end
        self
      end

      # Non-destructive version of rolling_fillna!
      def rolling_fillna(direction = :forward)
        dup.rolling_fillna!(direction)
      end

      # Non-destructive version of #replace_nils!
      def replace_nils(replacement)
        dup.replace_nils!(replacement)
      end

      # number of non-missing elements
      def n_valid
        size - indexes(*DaruLite::MISSING_VALUES).size
      end
      deprecate :n_valid, :count_values, 2016, 10

      # Creates a new vector consisting only of non-nil data
      #
      # == Arguments
      #
      # @param as_a [Symbol] Passing :array will return only the elements
      # as an Array. Otherwise will return a DaruLite::Vector.
      #
      # @param _duplicate [Symbol] In case no missing data is found in the
      # vector, setting this to false will return the same vector.
      # Otherwise, a duplicate will be returned irrespective of
      # presence of missing data.

      def only_valid(as_a = :vector, _duplicate = true) # rubocop:disable Style/OptionalBooleanParameter
        # FIXME: Now duplicate is just ignored.
        #   There are no spec that fail on this case, so I'll leave it
        #   this way for now - zverok, 2016-05-07

        new_index = @index.to_a - indexes(*DaruLite::MISSING_VALUES)
        new_vector = new_index.map { |idx| self[idx] }

        if as_a == :vector
          DaruLite::Vector.new new_vector, index: new_index, name: @name, dtype: dtype
        else
          new_vector
        end
      end
      deprecate :only_valid, :reject_values, 2016, 10

      # Returns a Vector containing only missing data (preserves indexes).
      def only_missing(as_a = :vector)
        case as_a
        when :vector
          self[*indexes(*DaruLite::MISSING_VALUES)]
        when :array
          self[*indexes(*DaruLite::MISSING_VALUES)].to_a
        end
      end
      deprecate :only_missing, nil, 2016, 10

      private

      # Helper method returning validity of arbitrary value
      def valid_value?(v)
        !((v.respond_to?(:nan?) && v.nan?) || v.nil?)
      end
    end
  end
end
