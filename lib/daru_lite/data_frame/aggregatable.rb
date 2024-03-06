module DaruLite
  class DataFrame
    module Aggregatable
      # Group elements by vector to perform operations on them. Returns a
      # DaruLite::Core::GroupBy object.See the DaruLite::Core::GroupBy docs for a detailed
      # list of possible operations.
      #
      # == Arguments
      #
      # * vectors - An Array contatining names of vectors to group by.
      #
      # == Usage
      #
      #   df = DaruLite::DataFrame.new({
      #     a: %w{foo bar foo bar   foo bar foo foo},
      #     b: %w{one one two three two two one three},
      #     c:   [1  ,2  ,3  ,1    ,3  ,6  ,3  ,8],
      #     d:   [11 ,22 ,33 ,44   ,55 ,66 ,77 ,88]
      #   })
      #   df.group_by([:a,:b,:c]).groups
      #   #=> {["bar", "one", 2]=>[1],
      #   # ["bar", "three", 1]=>[3],
      #   # ["bar", "two", 6]=>[5],
      #   # ["foo", "one", 1]=>[0],
      #   # ["foo", "one", 3]=>[6],
      #   # ["foo", "three", 8]=>[7],
      #   # ["foo", "two", 3]=>[2, 4]}
      def group_by(*vectors)
        vectors.flatten!
        missing = vectors - @vectors.to_a
        raise(ArgumentError, "Vector(s) missing: #{missing.join(', ')}") unless missing.empty?

        vectors = [@vectors.first] if vectors.empty?

        DaruLite::Core::GroupBy.new(self, vectors)
      end

      # Function to use for aggregating the data.
      #
      # @param options [Hash] options for column, you want in resultant dataframe
      #
      # @return [DaruLite::DataFrame]
      #
      # @example
      #   df = DaruLite::DataFrame.new(
      #      {col: [:a, :b, :c, :d, :e], num: [52,12,07,17,01]})
      #   => #<DaruLite::DataFrame(5x2)>
      #        col num
      #      0   a  52
      #      1   b  12
      #      2   c   7
      #      3   d  17
      #      4   e   1
      #
      #    df.aggregate(num_100_times: ->(df) { (df.num*100).first })
      #   => #<DaruLite::DataFrame(5x1)>
      #               num_100_ti
      #             0       5200
      #             1       1200
      #             2        700
      #             3       1700
      #             4        100
      #
      #   When we have duplicate index :
      #
      #   idx = DaruLite::CategoricalIndex.new [:a, :b, :a, :a, :c]
      #   df = DaruLite::DataFrame.new({num: [52,12,07,17,01]}, index: idx)
      #   => #<DaruLite::DataFrame(5x1)>
      #        num
      #      a  52
      #      b  12
      #      a   7
      #      a  17
      #      c   1
      #
      #   df.aggregate(num: :mean)
      #   => #<DaruLite::DataFrame(3x1)>
      #                      num
      #             a 25.3333333
      #             b         12
      #             c          1
      #
      # Note: `GroupBy` class `aggregate` method uses this `aggregate` method
      # internally.
      def aggregate(options = {}, multi_index_level = -1)
        if block_given?
          positions_tuples, new_index = yield(@index) # NOTE: use of yield is private for now
        else
          positions_tuples, new_index = group_index_for_aggregation(@index, multi_index_level)
        end

        colmn_value = aggregate_by_positions_tuples(options, positions_tuples)

        DaruLite::DataFrame.new(colmn_value, index: new_index, order: options.keys)
      end

      def group_by_and_aggregate(*group_by_keys, **aggregation_map)
        group_by(*group_by_keys).aggregate(aggregation_map)
      end

      private

      def aggregate_by_positions_tuples(options, positions_tuples)
        agg_over_vectors_only, options = cast_aggregation_options(options)

        if agg_over_vectors_only
          options.map do |vect_name, method|
            vect = self[vect_name]

            positions_tuples.map do |positions|
              vect.apply_method_on_sub_vector(method, keys: positions)
            end
          end
        else
          methods = options.values

          # NOTE: because we aggregate over rows, we don't have to re-get sub-dfs for each method (which is expensive)
          rows = positions_tuples.map do |positions|
            apply_method_on_sub_df(methods, keys: positions)
          end

          rows.transpose
        end
      end

      # convert operations over sub-vectors to operations over sub-dfs when it improves perf
      # note: we don't always "cast" because aggregation over a single vector / a few vector is faster
      #   than aggregation over (sub-)dfs
      def cast_aggregation_options(options)
        vects, non_vects = options.keys.partition { |k| @vectors.include?(k) }

        over_vectors = true

        if non_vects.any?
          options = options.clone

          vects.each do |name|
            proc_on_vect = options[name].to_proc
            options[name] = ->(sub_df) { proc_on_vect.call(sub_df[name]) }
          end

          over_vectors = false
        end

        [over_vectors, options]
      end

      def group_index_for_aggregation(index, multi_index_level = -1)
        case index
        when DaruLite::MultiIndex
          groups_by_pos = DaruLite::Core::GroupBy.get_positions_group_for_aggregation(index, multi_index_level)

          new_index = DaruLite::MultiIndex.from_tuples(groups_by_pos.keys).coerce_index
          pos_tuples = groups_by_pos.values
        when DaruLite::Index, DaruLite::CategoricalIndex
          new_index = Array(index).uniq
          pos_tuples = new_index.map { |idx| [*index.pos(idx)] }
        else raise
        end

        [pos_tuples, new_index]
      end
    end
  end
end
