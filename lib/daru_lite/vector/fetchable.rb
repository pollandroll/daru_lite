module DaruLite
  class Vector
    module Fetchable
      # Get one or more elements with specified index or a range.
      #
      # == Usage
      #   # For vectors employing single layer Index
      #
      #   v[:one, :two] # => DaruLite::Vector with indexes :one and :two
      #   v[:one]       # => Single element
      #   v[:one..:three] # => DaruLite::Vector with indexes :one, :two and :three
      #
      #   # For vectors employing hierarchial multi index
      #
      def [](*input_indexes)
        # Get array of positions indexes
        positions = @index.pos(*input_indexes)

        # If one object is asked return it
        return @data[positions] if positions.is_a? Numeric

        # Form a new Vector using positional indexes
        DaruLite::Vector.new(
          positions.map { |loc| @data[loc] },
          name: @name,
          index: @index.subset(*input_indexes), dtype: @dtype
        )
      end

      # Returns vector of values given positional values
      # @param positions [Array<object>] positional values
      # @return [object] vector
      # @example
      #   dv = DaruLite::Vector.new 'a'..'e'
      #   dv.at 0, 1, 2
      #   # => #<DaruLite::Vector(3)>
      #   #   0   a
      #   #   1   b
      #   #   2   c
      def at(*positions)
        # to be used to form index
        original_positions = positions
        positions = coerce_positions(*positions)
        validate_positions(*positions)

        if positions.is_a? Integer
          @data[positions]
        else
          values = positions.map { |pos| @data[pos] }
          DaruLite::Vector.new values, index: @index.at(*original_positions), dtype: dtype
        end
      end

      def head(q = 10)
        self[0..(q - 1)]
      end

      def tail(q = 10)
        start = [size - q, 0].max
        self[start..(size - 1)]
      end

      def last(q = 1)
        # The Enumerable mixin dose not provide the last method.
        tail(q)
      end

      # Returns a hash of Vectors, defined by the different values
      # defined on the fields
      # Example:
      #
      #  a=DaruLite::Vector.new(["a,b","c,d","a,b"])
      #  a.split_by_separator
      #  =>  {"a"=>#<DaruLite::Vector:0x7f2dbcc09d88
      #        @data=[1, 0, 1]>,
      #       "b"=>#<DaruLite::Vector:0x7f2dbcc09c48
      #        @data=[1, 1, 0]>,
      #      "c"=>#<DaruLite::Vector:0x7f2dbcc09b08
      #        @data=[0, 1, 1]>}
      #
      def split_by_separator(sep = ',')
        split_data = splitted sep
        split_data
          .flatten.uniq.compact.to_h do |key|
          [
            key,
            DaruLite::Vector.new(split_data.map { |v| split_value(key, v) })
          ]
        end
      end

      def split_by_separator_freq(sep = ',')
        split_by_separator(sep).transform_values do |v|
          v.sum(&:to_i)
        end
      end

      # @param keys [Array] can be positions (if by_position is true) or indexes (if by_position if false)
      # @return [DaruLite::Vector]
      def get_sub_vector(keys, by_position: true)
        return DaruLite::Vector.new([]) if keys == []

        keys = @index.pos(*keys) unless by_position

        sub_vect = at(*keys)
        sub_vect = DaruLite::Vector.new([sub_vect]) unless sub_vect.is_a?(DaruLite::Vector)

        sub_vect
      end

      # Partition a numeric variable into categories.
      # @param [Array<Numeric>] partitions an array whose consecutive elements
      #   provide intervals for categories
      # @param [Hash] opts options to cut the partition
      # @option opts [:left, :right] :close_at specifies whether the interval closes at
      #   the right side of left side
      # @option opts [Array] :labels names of the categories
      # @return [DaruLite::Vector] numeric variable converted to categorical variable
      # @example
      #   heights = DaruLite::Vector.new [30, 35, 32, 50, 42, 51]
      #   height_cat = heights.cut [30, 40, 50, 60], labels=['low', 'medium', 'high']
      #   # => #<DaruLite::Vector(6)>
      #   #       0    low
      #   #       1    low
      #   #       2    low
      #   #       3   high
      #   #       4 medium
      #   #       5   high
      def cut(partitions, opts = {})
        close_at = opts[:close_at] || :right
        labels = opts[:labels]
        partitions = partitions.to_a
        values = to_a.map { |val| cut_find_category partitions, val, close_at }
        cats = cut_categories(partitions, close_at)

        dv = DaruLite::Vector.new values,
                                  index: @index,
                                  type: :category,
                                  categories: cats

        # Rename categories if new labels provided
        if labels
          dv.rename_categories cats.zip(labels).to_h
        else
          dv
        end
      end

      def positions(*values)
        case values
        when [nil]
          nil_positions
        when [Float::NAN]
          nan_positions
        when [nil, Float::NAN], [Float::NAN, nil]
          nil_positions + nan_positions
        else
          size.times.select { |i| include_with_nan? values, @data[i] }
        end
      end

      private

      def split_value(key, v)
        if v.nil?
          nil
        elsif v.include?(key)
          1
        else
          0
        end
      end
    end
  end
end
