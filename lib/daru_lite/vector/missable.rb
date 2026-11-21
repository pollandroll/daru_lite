module DaruLite
  class Vector
    module Missable
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

      private

      # Helper method returning validity of arbitrary value
      def valid_value?(v)
        !((v.respond_to?(:nan?) && v.nan?) || v.nil?)
      end
    end
  end
end
