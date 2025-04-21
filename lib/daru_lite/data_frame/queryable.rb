module DaruLite
  class DataFrame
    module Queryable
      # Check if a vector is present
      def has_vector?(vector)
        @vectors.include? vector
      end

      # Check if any of given values occur in the data frame
      # @param [Array] values to check for
      # @return [true, false] true if any of the given values occur in the
      #   dataframe, false otherwise
      # @example
      #   df = DaruLite::DataFrame.new({
      #     a: [1,    2,          3,   nil,        Float::NAN, nil, 1,   7],
      #     b: [:a,  :b,          nil, Float::NAN, nil,        3,   5,   8],
      #     c: ['a',  Float::NAN, 3,   4,          3,          5,   nil, 7]
      #   }, index: 11..18)
      #   df.include_values? nil
      #   # => true
      def include_values?(*values)
        @data.any? { |vec| vec.include_values?(*values) }
      end

      # Works like Array#any?.
      #
      # @param [Symbol] axis (:vector) The axis to iterate over. Can be :vector or
      #   :row. A DaruLite::Vector object is yielded in the block.
      # @example Using any?
      #   df = DaruLite::DataFrame.new({a: [1,2,3,4,5], b: ['a', 'b', 'c', 'd', 'e']})
      #   df.any?(:row) do |row|
      #     row[:a] < 3 and row[:b] == 'b'
      #   end #=> true
      def any?(axis = :vector, &)
        if %i[vector column].include?(axis)
          @data.any?(&)
        elsif axis == :row
          each_row do |row|
            return true if yield(row)
          end
          false
        else
          raise ArgumentError, "Unidentified axis #{axis}"
        end
      end

      # Works like Array#all?
      #
      # @param [Symbol] axis (:vector) The axis to iterate over. Can be :vector or
      #   :row. A DaruLite::Vector object is yielded in the block.
      # @example Using all?
      #   df = DaruLite::DataFrame.new({a: [1,2,3,4,5], b: ['a', 'b', 'c', 'd', 'e']})
      #   df.all?(:row) do |row|
      #     row[:a] < 10
      #   end #=> true
      def all?(axis = :vector, &)
        if %i[vector column].include?(axis)
          @data.all?(&)
        elsif axis == :row
          each_row.all?(&)
        else
          raise ArgumentError, "Unidentified axis #{axis}"
        end
      end
    end
  end
end
