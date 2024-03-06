module DaruLite
  class DataFrame
    module Iterable
      # Iterate over each index of the DataFrame.
      def each_index(&block)
        return to_enum(:each_index) unless block

        @index.each(&block)

        self
      end

      # Iterate over each vector
      def each_vector(&block)
        return to_enum(:each_vector) unless block

        @data.each(&block)

        self
      end

      alias each_column each_vector

      # Iterate over each vector alongwith the name of the vector
      def each_vector_with_index
        return to_enum(:each_vector_with_index) unless block_given?

        @vectors.each do |vector|
          yield @data[@vectors[vector]], vector
        end

        self
      end

      alias each_column_with_index each_vector_with_index

      # Iterate over each row
      def each_row
        return to_enum(:each_row) unless block_given?

        @index.size.times do |pos|
          yield row_at(pos)
        end

        self
      end

      def each_row_with_index
        return to_enum(:each_row_with_index) unless block_given?

        @index.each do |index|
          yield access_row(index), index
        end

        self
      end

      # Iterate over each row or vector of the DataFrame. Specify axis
      # by passing :vector or :row as the argument. Default to :vector.
      #
      # == Description
      #
      # `#each` works exactly like Array#each. The default mode for `each`
      # is to iterate over the columns of the DataFrame. To iterate over
      # rows you must pass the axis, i.e `:row` as an argument.
      #
      # == Arguments
      #
      # * +axis+ - The axis to iterate over. Can be :vector (or :column)
      # or :row. Default to :vector.
      def each(axis = :vector, &block)
        dispatch_to_axis axis, :each, &block
      end

      # Iterate over a row or vector and return results in a DaruLite::Vector.
      # Specify axis with :vector or :row. Default to :vector.
      #
      # == Description
      #
      # The #collect iterator works similar to #map, the only difference
      # being that it returns a DaruLite::Vector comprising of the results of
      # each block run. The resultant Vector has the same index as that
      # of the axis over which collect has iterated. It also accepts the
      # optional axis argument.
      #
      # == Arguments
      #
      # * +axis+ - The axis to iterate over. Can be :vector (or :column)
      # or :row. Default to :vector.
      def collect(axis = :vector, &block)
        dispatch_to_axis_pl axis, :collect, &block
      end

      # Map over each vector or row of the data frame according to
      # the argument specified. Will return an Array of the resulting
      # elements. To map over each row/vector and get a DataFrame,
      # see #recode.
      #
      # == Description
      #
      # The #map iterator works like Array#map. The value returned by
      # each run of the block is added to an Array and the Array is
      # returned. This method also accepts an axis argument, like #each.
      # The default is :vector.
      #
      # == Arguments
      #
      # * +axis+ - The axis to map over. Can be :vector (or :column) or :row.
      # Default to :vector.
      def map(axis = :vector, &block)
        dispatch_to_axis_pl axis, :map, &block
      end

      # Destructive map. Modifies the DataFrame. Each run of the block
      # must return a DaruLite::Vector. You can specify the axis to map over
      # as the argument. Default to :vector.
      #
      # == Arguments
      #
      # * +axis+ - The axis to map over. Can be :vector (or :column) or :row.
      # Default to :vector.
      def map!(axis = :vector, &block)
        if %i[vector column].include?(axis)
          map_vectors!(&block)
        elsif axis == :row
          map_rows!(&block)
        end
      end

      # Maps over the DataFrame and returns a DataFrame. Each run of the
      # block must return a DaruLite::Vector object. You can specify the axis
      # to map over. Default to :vector.
      #
      # == Description
      #
      # Recode works similarly to #map, but an important difference between
      # the two is that recode returns a modified DaruLite::DataFrame instead
      # of an Array. For this reason, #recode expects that every run of the
      # block to return a DaruLite::Vector.
      #
      # Just like map and each, recode also accepts an optional _axis_ argument.
      #
      # == Arguments
      #
      # * +axis+ - The axis to map over. Can be :vector (or :column) or :row.
      # Default to :vector.
      def recode(axis = :vector, &block)
        dispatch_to_axis_pl axis, :recode, &block
      end

      # Replace specified values with given value
      # @param [Array] old_values values to replace with new value
      # @param [object] new_value new value to replace with
      # @return [DaruLite::DataFrame] Data Frame itself with old values replace
      #   with new value
      # @example
      #   df = DaruLite::DataFrame.new({
      #     a: [1,    2,          3,   nil,        Float::NAN, nil, 1,   7],
      #     b: [:a,  :b,          nil, Float::NAN, nil,        3,   5,   8],
      #     c: ['a',  Float::NAN, 3,   4,          3,          5,   nil, 7]
      #   }, index: 11..18)
      #   df.replace_values nil, Float::NAN
      #   # => #<DaruLite::DataFrame(8x3)>
      #   #       a   b   c
      #   #   11   1   a   a
      #   #   12   2   b NaN
      #   #   13   3 NaN   3
      #   #   14 NaN NaN   4
      #   #   15 NaN NaN   3
      #   #   16 NaN   3   5
      #   #   17   1   5 NaN
      #   #   18   7   8   7
      def replace_values(old_values, new_value)
        @data.each { |vec| vec.replace_values old_values, new_value }
        self
      end

      # Test each row with one or more tests.
      # @param tests [Proc]  Each test is a Proc with the form
      #                      *Proc.new {|row| row[:age] > 0}*
      # The function returns an array with all errors.
      #
      # FIXME: description here is too sparse. As far as I can get,
      # it should tell something about that each test is [descr, fields, block],
      # and that first value may be column name to output. - zverok, 2016-05-18
      def verify(*tests)
        id = tests.first.is_a?(Symbol) ? tests.shift : @vectors.first

        each_row_with_index.map do |row, i|
          tests.reject { |*_, block| block.call(row) }
               .map { |test| verify_error_message row, test, id, i }
        end.flatten
      end

      def recode_vectors
        block_given? or return to_enum(:recode_vectors)

        dup.tap do |df|
          df.each_vector_with_index do |v, i|
            df[*i] = should_be_vector!(yield(v))
          end
        end
      end

      def recode_rows
        block_given? or return to_enum(:recode_rows)

        dup.tap do |df|
          df.each_row_with_index do |r, i|
            df.row[i] = should_be_vector!(yield(r))
          end
        end
      end

      # Map each vector and return an Array.
      def map_vectors(&block)
        return to_enum(:map_vectors) unless block

        @data.map(&block)
      end

      # Destructive form of #map_vectors
      def map_vectors!
        return to_enum(:map_vectors!) unless block_given?

        vectors.dup.each do |n|
          self[n] = should_be_vector!(yield(self[n]))
        end

        self
      end

      # Map vectors alongwith the index.
      def map_vectors_with_index(&block)
        return to_enum(:map_vectors_with_index) unless block

        each_vector_with_index.map(&block)
      end

      # Map each row
      def map_rows(&block)
        return to_enum(:map_rows) unless block

        each_row.map(&block)
      end

      def map_rows_with_index(&block)
        return to_enum(:map_rows_with_index) unless block

        each_row_with_index.map(&block)
      end

      def map_rows!
        return to_enum(:map_rows!) unless block_given?

        index.dup.each do |i|
          row[i] = should_be_vector!(yield(row[i]))
        end

        self
      end

      def apply_method(method, keys: nil, by_position: true)
        df = keys ? get_sub_dataframe(keys, by_position: by_position) : self

        case method
        when Symbol then df.send(method)
        when Proc   then method.call(df)
        when Array
          method.map(&:to_proc).map { |proc| proc.call(df) } # works with Array of both Symbol and/or Proc
        else raise
        end
      end
      alias apply_method_on_sub_df apply_method

      # Retrieves a DaruLite::Vector, based on the result of calculation
      # performed on each row.
      def collect_rows(&block)
        return to_enum(:collect_rows) unless block

        DaruLite::Vector.new(each_row.map(&block), index: @index)
      end

      def collect_row_with_index(&block)
        return to_enum(:collect_row_with_index) unless block

        DaruLite::Vector.new(each_row_with_index.map(&block), index: @index)
      end

      # Retrives a DaruLite::Vector, based on the result of calculation
      # performed on each vector.
      def collect_vectors(&block)
        return to_enum(:collect_vectors) unless block

        DaruLite::Vector.new(each_vector.map(&block), index: @vectors)
      end

      def collect_vector_with_index(&block)
        return to_enum(:collect_vector_with_index) unless block

        DaruLite::Vector.new(each_vector_with_index.map(&block), index: @vectors)
      end

      # Generate a matrix, based on vector names of the DataFrame.
      #
      # @return {::Matrix}
      # :nocov:
      # FIXME: Even not trying to cover this: I can't get, how it is expected
      # to work.... -- zverok
      def collect_matrix
        return to_enum(:collect_matrix) unless block_given?

        vecs = vectors.to_a
        rows = vecs.collect do |row|
          vecs.collect do |col|
            yield row, col
          end
        end

        Matrix.rows(rows)
      end
      # :nocov:

      private

      def should_be_vector!(val)
        return val if val.is_a?(DaruLite::Vector)

        raise TypeError, "Every iteration must return DaruLite::Vector not #{val.class}"
      end

      def verify_error_message(row, test, id, i)
        description, fields, = test
        values = fields.empty? ? '' : " (#{fields.collect { |k| "#{k}=#{row[k]}" }.join(', ')})"
        "#{i + 1} [#{row[id]}]: #{description}#{values}"
      end
    end
  end
end
