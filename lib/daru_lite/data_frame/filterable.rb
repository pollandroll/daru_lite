module DaruLite
  class DataFrame
    module Filterable
      # Return unique rows by vector specified or all vectors
      #
      # @param vtrs [String][Symbol] vector names(s) that should be considered
      #
      # @example
      #
      #    => #<DaruLite::DataFrame(6x2)>
      #         a   b
      #     0   1   a
      #     1   2   b
      #     2   3   c
      #     3   4   d
      #     2   3   c
      #     3   4   f
      #
      #    2.3.3 :> df.uniq
      #    => #<DaruLite::DataFrame(5x2)>
      #         a   b
      #     0   1   a
      #     1   2   b
      #     2   3   c
      #     3   4   d
      #     3   4   f
      #
      #    2.3.3 :> df.uniq(:a)
      #    => #<DaruLite::DataFrame(5x2)>
      #         a   b
      #     0   1   a
      #     1   2   b
      #     2   3   c
      #     3   4   d
      #
      def uniq(*vtrs)
        vecs = vtrs.empty? ? vectors.to_a : Array(vtrs)
        grouped = group_by(vecs)
        indexes = grouped.groups.values.map { |v| v[0] }.sort
        row[*indexes]
      end

      # Retain vectors or rows if the block returns a truthy value.
      #
      # == Description
      #
      # For filtering out certain rows/vectors based on their values,
      # use the #filter method. By default it iterates over vectors and
      # keeps those vectors for which the block returns true. It accepts
      # an optional axis argument which lets you specify whether you want
      # to iterate over vectors or rows.
      #
      # == Arguments
      #
      # * +axis+ - The axis to map over. Can be :vector (or :column) or :row.
      # Default to :vector.
      #
      # == Usage
      #
      #   # Filter vectors
      #
      #   df.filter do |vector|
      #     vector.type == :numeric and vector.median < 50
      #   end
      #
      #   # Filter rows
      #
      #   df.filter(:row) do |row|
      #     row[:a] + row[:d] < 100
      #   end
      def filter(axis = :vector, &block)
        dispatch_to_axis_pl axis, :filter, &block
      end

      # Returns a dataframe in which rows with any of the mentioned values
      # are ignored.
      # @param [Array] values to reject to form the new dataframe
      # @return [DaruLite::DataFrame] Data Frame with only rows which doesn't
      #   contain the mentioned values
      # @example
      #   df = DaruLite::DataFrame.new({
      #     a: [1,    2,          3,   nil,        Float::NAN, nil, 1,   7],
      #     b: [:a,  :b,          nil, Float::NAN, nil,        3,   5,   8],
      #     c: ['a',  Float::NAN, 3,   4,          3,          5,   nil, 7]
      #   }, index: 11..18)
      #   df.reject_values nil, Float::NAN
      #   # => #<DaruLite::DataFrame(2x3)>
      #   #       a   b   c
      #   #   11   1   a   a
      #   #   18   7   8   7
      def reject_values(*values)
        positions =
          size.times.to_a - @data.flat_map { |vec| vec.positions(*values) }
        # Handle the case when positions size is 1 and #row_at wouldn't return a df
        if positions.size == 1
          pos = positions.first
          row_at(pos..pos)
        else
          row_at(*positions)
        end
      end

      def keep_row_if
        @index
          .reject { |idx| yield access_row(idx) }
          .each { |idx| delete_row idx }
      end

      def keep_vector_if
        @vectors.each do |vector|
          delete_vector(vector) unless yield(@data[@vectors[vector]], vector)
        end
      end

      # creates a new vector with the data of a given field which the block returns true
      def filter_vector(vec, &block)
        DaruLite::Vector.new(each_row.select(&block).map { |row| row[vec] })
      end

      # Iterates over each row and retains it in a new DataFrame if the block returns
      # true for that row.
      def filter_rows
        return to_enum(:filter_rows) unless block_given?

        keep_rows = @index.map { |index| yield access_row(index) }

        where keep_rows
      end

      # Iterates over each vector and retains it in a new DataFrame if the block returns
      # true for that vector.
      def filter_vectors(&block)
        return to_enum(:filter_vectors) unless block

        dup.tap { |df| df.keep_vector_if(&block) }
      end

      # Query a DataFrame by passing a DaruLite::Core::Query::BoolArray object.
      def where(bool_array)
        DaruLite::Core::Query.df_where self, bool_array
      end
    end
  end
end
