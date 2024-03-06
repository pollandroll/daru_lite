module DaruLite
  class DataFrame
    module Missable
      extend Gem::Deprecate

      # Rolling fillna
      # replace all Float::NAN and NIL values with the preceeding or following value
      #
      # @param direction [Symbol] (:forward, :backward) whether replacement value is preceeding or following
      #
      # @example
      #   df = DaruLite::DataFrame.new({
      #    a: [1,    2,          3,   nil,        Float::NAN, nil, 1,   7],
      #    b: [:a,  :b,          nil, Float::NAN, nil,        3,   5,   nil],
      #    c: ['a',  Float::NAN, 3,   4,          3,          5,   nil, 7]
      #   })
      #
      #   => #<DaruLite::DataFrame(8x3)>
      #        a   b   c
      #    0   1   a   a
      #    1   2   b NaN
      #    2   3 nil   3
      #    3 nil NaN   4
      #    4 NaN nil   3
      #    5 nil   3   5
      #    6   1   5 nil
      #    7   7 nil   7
      #
      #   2.3.3 :068 > df.rolling_fillna(:forward)
      #   => #<DaruLite::DataFrame(8x3)>
      #        a   b   c
      #    0   1   a   a
      #    1   2   b   a
      #    2   3   b   3
      #    3   3   b   4
      #    4   3   b   3
      #    5   3   3   5
      #    6   1   5   5
      #    7   7   5   7
      #
      def rolling_fillna!(direction = :forward)
        @data.each { |vec| vec.rolling_fillna!(direction) }
        self
      end

      def rolling_fillna(direction = :forward)
        dup.rolling_fillna!(direction)
      end

      # Return a vector with the number of missing values in each row.
      #
      # == Arguments
      #
      # * +missing_values+ - An Array of the values that should be
      # treated as 'missing'. The default missing value is *nil*.
      def missing_values_rows(missing_values = [nil])
        number_of_missing = each_row.map do |row|
          row.indexes(*missing_values).size
        end

        DaruLite::Vector.new number_of_missing, index: @index, name: "#{@name}_missing_rows"
      end

      # TODO: remove next version
      alias vector_missing_values missing_values_rows

      def has_missing_data?
        @data.any? { |vec| vec.include_values?(*DaruLite::MISSING_VALUES) }
      end
      alias flawed? has_missing_data?
      deprecate :has_missing_data?, :include_values?, 2016, 10
      deprecate :flawed?, :include_values?, 2016, 10
    end
  end
end
