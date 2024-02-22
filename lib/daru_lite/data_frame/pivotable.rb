module DaruLite
  class DataFrame
    module Pivotable
      # Pivots a data frame on specified vectors and applies an aggregate function
      # to quickly generate a summary.
      #
      # == Options
      #
      # +:index+ - Keys to group by on the pivot table row index. Pass vector names
      # contained in an Array.
      #
      # +:vectors+ - Keys to group by on the pivot table column index. Pass vector
      # names contained in an Array.
      #
      # +:agg+ - Function to aggregate the grouped values. Default to *:mean*. Can
      # use any of the statistics functions applicable on Vectors that can be found in
      # the DaruLite::Statistics::Vector module.
      #
      # +:values+ - Columns to aggregate. Will consider all numeric columns not
      # specified in *:index* or *:vectors*. Optional.
      #
      # == Usage
      #
      #   df = DaruLite::DataFrame.new({
      #     a: ['foo'  ,  'foo',  'foo',  'foo',  'foo',  'bar',  'bar',  'bar',  'bar'],
      #     b: ['one'  ,  'one',  'one',  'two',  'two',  'one',  'one',  'two',  'two'],
      #     c: ['small','large','large','small','small','large','small','large','small'],
      #     d: [1,2,2,3,3,4,5,6,7],
      #     e: [2,4,4,6,6,8,10,12,14]
      #   })
      #   df.pivot_table(index: [:a], vectors: [:b], agg: :sum, values: :e)
      #
      #   #=>
      #   # #<DaruLite::DataFrame:88342020 @name = 08cdaf4e-b154-4186-9084-e76dd191b2c9 @size = 2>
      #   #            [:e, :one] [:e, :two]
      #   #     [:bar]         18         26
      #   #     [:foo]         10         12
      def pivot_table(opts = {})
        raise ArgumentError, 'Specify grouping index' if Array(opts[:index]).empty?

        index               = opts[:index]
        vectors             = opts[:vectors] || []
        aggregate_function  = opts[:agg] || :mean
        values              = prepare_pivot_values index, vectors, opts
        raise IndexError, 'No numeric vectors to aggregate' if values.empty?

        grouped = group_by(index)
        return grouped.send(aggregate_function) if vectors.empty?

        super_hash = make_pivot_hash grouped, vectors, values, aggregate_function

        pivot_dataframe super_hash
      end

      private

      def prepare_pivot_values(index, vectors, opts)
        case opts[:values]
        when nil # values not specified at all.
          (@vectors.to_a - (index | vectors)) & numeric_vector_names
        when Array # multiple values specified.
          opts[:values]
        else # single value specified.
          [opts[:values]]
        end
      end

      def make_pivot_hash(grouped, vectors, values, aggregate_function)
        grouped.groups.transform_values { |_| {} }.tap do |super_hash|
          values.each do |value|
            grouped.groups.each do |group_name, row_numbers|
              row_numbers.each do |num|
                arry = [value, *vectors.map { |v| self[v][num] }]
                sub_hash = super_hash[group_name]
                sub_hash[arry] ||= []

                sub_hash[arry] << self[value][num]
              end
            end
          end

          setup_pivot_aggregates super_hash, aggregate_function
        end
      end

      def setup_pivot_aggregates(super_hash, aggregate_function)
        super_hash.each_value do |sub_hash|
          sub_hash.each do |group_name, aggregates|
            sub_hash[group_name] = DaruLite::Vector.new(aggregates).send(aggregate_function)
          end
        end
      end

      def pivot_dataframe(super_hash)
        df_index   = DaruLite::MultiIndex.from_tuples super_hash.keys
        df_vectors = DaruLite::MultiIndex.from_tuples super_hash.values.flat_map(&:keys).uniq

        DaruLite::DataFrame.new({}, index: df_index, order: df_vectors).tap do |pivoted_dataframe|
          super_hash.each do |row_index, sub_h|
            sub_h.each do |vector_index, val|
              pivoted_dataframe[vector_index][row_index] = val
            end
          end
        end
      end
    end
  end
end
