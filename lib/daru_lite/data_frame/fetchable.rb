module DaruLite
  class DataFrame
    module Fetchable
      # Access row or vector. Specify name of row/vector followed by axis(:row, :vector).
      # Defaults to *:vector*. Use of this method is not recommended for accessing
      # rows. Use df.row[:a] for accessing row with index ':a'.
      def [](*names)
        axis = extract_axis(names, :vector)
        dispatch_to_axis axis, :access, *names
      end

      # Retrive rows by positions
      # @param [Array<Integer>] positions of rows to retrive
      # @return [DaruLite::Vector, DaruLite::DataFrame] vector for single position and dataframe for multiple positions
      # @example
      #   df = DaruLite::DataFrame.new({
      #     a: [1, 2, 3],
      #     b: ['a', 'b', 'c']
      #   })
      #   df.row_at 1, 2
      #   # => #<DaruLite::DataFrame(2x2)>
      #   #       a   b
      #   #   1   2   b
      #   #   2   3   c
      def row_at(*positions)
        original_positions = positions
        positions = coerce_positions(*positions, nrows)
        validate_positions(*positions, nrows)

        if positions.is_a? Integer
          row = get_rows_for([positions])
          DaruLite::Vector.new(row, index: @vectors, name: @index.at(positions))
        else
          new_rows = get_rows_for(original_positions)
          DaruLite::DataFrame.new(
            new_rows,
            index: @index.at(*original_positions),
            order: @vectors,
            name: @name
          )
        end
      end

      # Retrive vectors by positions
      # @param [Array<Integer>] positions of vectors to retrive
      # @return [DaruLite::Vector, DaruLite::DataFrame] vector for single position and dataframe for multiple positions
      # @example
      #   df = DaruLite::DataFrame.new({
      #     a: [1, 2, 3],
      #     b: ['a', 'b', 'c']
      #   })
      #   df.at 0
      #   # => #<DaruLite::Vector(3)>
      #   #       a
      #   #   0   1
      #   #   1   2
      #   #   2   3
      def at(*positions)
        if AXES.include? positions.last
          axis = positions.pop
          return row_at(*positions) if axis == :row
        end

        original_positions = positions
        positions = coerce_positions(*positions, ncols)
        validate_positions(*positions, ncols)

        if positions.is_a? Integer
          @data[positions].dup
        else
          DaruLite::DataFrame.new positions.map { |pos| @data[pos].dup },
                                  index: @index,
                                  order: @vectors.at(*original_positions),
                                  name: @name
        end
      end

      # The first ten elements of the DataFrame
      #
      # @param [Fixnum] quantity (10) The number of elements to display from the top.
      def head(quantity = 10)
        row.at 0..(quantity - 1)
      end
      alias first head

      # The last ten elements of the DataFrame
      #
      # @param [Fixnum] quantity (10) The number of elements to display from the bottom.
      def tail(quantity = 10)
        start = [-quantity, -size].max
        row.at start..-1
      end
      alias last tail

      # Extract a dataframe given row indexes or positions
      # @param keys [Array] can be positions (if by_position is true) or indexes (if by_position if false)
      # @return [DaruLite::Dataframe]
      def get_sub_dataframe(keys, by_position: true)
        return DaruLite::DataFrame.new({}) if keys == []

        keys = @index.pos(*keys) unless by_position

        sub_df = row_at(*keys)
        sub_df = sub_df.to_df.transpose if sub_df.is_a?(DaruLite::Vector)

        sub_df
      end

      def get_vector_anyways(v)
        @vectors.include?(v) ? self[v].to_a : Array.new(size)
      end

      # @param indexes [Array] index(s) at which row tuples are retrieved
      # @return [Array] returns array of row tuples at given index(s)
      # @example Using DaruLite::Index
      #   df = DaruLite::DataFrame.new({
      #     a: [1, 2, 3],
      #     b: ['a', 'a', 'b']
      #   })
      #
      #   df.access_row_tuples_by_indexs(1,2)
      #   # => [[2, "a"], [3, "b"]]
      #
      #   df.index = DaruLite::Index.new([:one,:two,:three])
      #   df.access_row_tuples_by_indexs(:one,:three)
      #   # => [[1, "a"], [3, "b"]]
      #
      # @example Using DaruLite::MultiIndex
      #   mi_idx = DaruLite::MultiIndex.from_tuples [
      #     [:a,:one,:bar],
      #     [:a,:one,:baz],
      #     [:b,:two,:bar],
      #     [:a,:two,:baz],
      #   ]
      #   df_mi = DaruLite::DataFrame.new({
      #     a: 1..4,
      #     b: 'a'..'d'
      #   }, index: mi_idx )
      #
      #   df_mi.access_row_tuples_by_indexs(:b, :two, :bar)
      #   # => [[3, "c"]]
      #   df_mi.access_row_tuples_by_indexs(:a)
      #   # => [[1, "a"], [2, "b"], [4, "d"]]
      def access_row_tuples_by_indexs(*indexes)
        return get_sub_dataframe(indexes, by_position: false).map_rows(&:to_a) if
        @index.is_a?(DaruLite::MultiIndex)

        positions = @index.pos(*indexes)
        if positions.is_a? Numeric
          row = get_rows_for([positions])
          row.first.is_a?(Array) ? row : [row]
        else
          new_rows = get_rows_for(indexes, by_position: false)
          indexes.map { |index| new_rows.map { |r| r[index] } }
        end
      end

      # Split the dataframe into many dataframes based on category vector
      # @param [object] cat_name name of category vector to split the dataframe
      # @return [Array] array of dataframes split by category with category vector
      #   used to split not included
      # @example
      #   df = DaruLite::DataFrame.new({
      #     a: [1, 2, 3],
      #     b: ['a', 'a', 'b']
      #   })
      #   df.to_category :b
      #   df.split_by_category :b
      #   # => [#<DaruLite::DataFrame: a (2x1)>
      #   #       a
      #   #   0   1
      #   #   1   2,
      #   # #<DaruLite::DataFrame: b (1x1)>
      #   #       a
      #   #   2   3]
      def split_by_category(cat_name)
        cat_dv = self[cat_name]
        raise ArgumentError, "#{cat_name} is not a category vector" unless
          cat_dv.category?

        cat_dv.categories.map do |cat|
          where(cat_dv.eq cat)
            .rename(cat)
            .delete_vector cat_name
        end
      end

      # Return the indexes of all the numeric vectors. Will include vectors with nils
      # alongwith numbers.
      def numeric_vectors
        # FIXME: Why _with_index ?..
        each_vector_with_index
          .select { |vec, _i| vec.numeric? }
          .map(&:last)
      end

      def numeric_vector_names
        @vectors.select { |v| self[v].numeric? }
      end

      # Return a DataFrame of only the numerical Vectors. If clone: false
      # is specified as option, only a *view* of the Vectors will be
      # returned. Defaults to clone: true.
      def only_numerics(opts = {})
        cln = opts[:clone] != false
        arry = numeric_vectors.map { |v| self[v] }

        order = Index.new(numeric_vectors)
        DaruLite::DataFrame.new(arry, clone: cln, order: order, index: @index)
      end

      private

      def access_vector(*names)
        if names.first.is_a?(Range)
          dup(@vectors.subset(names.first))
        elsif @vectors.is_a?(MultiIndex)
          access_vector_multi_index(*names)
        else
          access_vector_single_index(*names)
        end
      end

      def access_vector_multi_index(*names)
        pos = @vectors[names]

        return @data[pos] if pos.is_a?(Integer)

        new_vectors = pos.map { |tuple| @data[@vectors[tuple]] }

        pos = pos.drop_left_level(names.size) if names.size < @vectors.width

        DaruLite::DataFrame.new(new_vectors, index: @index, order: pos)
      end

      def access_vector_single_index(*names)
        if names.count < 2
          begin
            pos = @vectors.is_a?(DaruLite::DateTimeIndex) ? @vectors[names.first] : @vectors.pos(names.first)
          rescue IndexError
            raise IndexError, "Specified vector #{names.first} does not exist"
          end
          return @data[pos] if pos.is_a?(Numeric)

          names = pos
        end

        new_vectors = names.map { |name| [name, @data[@vectors.pos(name)]] }.to_h

        order = names.is_a?(Array) ? DaruLite::Index.new(names) : names
        DaruLite::DataFrame.new(new_vectors, order: order, index: @index, name: @name)
      end

      def access_row(*indexes)
        positions = @index.pos(*indexes)

        if positions.is_a? Numeric
          row = get_rows_for([positions])
          DaruLite::Vector.new row, index: @vectors, name: indexes.first
        else
          new_rows = get_rows_for(indexes, by_position: false)
          DaruLite::DataFrame.new new_rows, index: @index.subset(*indexes), order: @vectors
        end
      end

      # @param keys [Array] can be an array of positions (if by_position is true) or indexes (if by_position if false)
      # because of coercion by DaruLite::Vector#at and DaruLite::Vector#[], can return either an Array of
      #   values (representing a row) or an array of Vectors (that can be seen as rows)
      def get_rows_for(keys, by_position: true)
        raise unless keys.is_a?(Array)

        if by_position
          pos = keys
          @data.map { |vector| vector.at(*pos) }
        else
          # TODO: for now (2018-07-27), it is different than using
          #    get_rows_for(@index.pos(*keys))
          #    because DaruLite::Vector#at and DaruLite::Vector#[] don't handle DaruLite::MultiIndex the same way
          indexes = keys
          @data.map { |vec| vec[*indexes] }
        end
      end

      # coerce ranges, integers and array in appropriate ways
      def coerce_positions(*positions, size)
        if positions.size == 1
          case positions.first
          when Integer
            positions.first
          when Range
            size.times.to_a[positions.first]
          else
            raise ArgumentError, 'Unknown position type.'
          end
        else
          positions
        end
      end
    end
  end
end
