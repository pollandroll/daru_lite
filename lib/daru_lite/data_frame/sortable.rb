module DaruLite
  class DataFrame
    module Sortable
      # Reorder the vectors in a dataframe
      # @param [Array] order_array new order of the vectors
      # @example
      #   df = DaruLite::DataFrame({
      #     a: [1, 2, 3],
      #     b: [4, 5, 6]
      #   }, order: [:a, :b])
      #   df.order = [:b, :a]
      #   df
      #   # => #<DaruLite::DataFrame(3x2)>
      #   #       b   a
      #   #   0   4   1
      #   #   1   5   2
      #   #   2   6   3
      def order=(order_array)
        raise ArgumentError, 'Invalid order' unless
          order_array.sort_by(&:to_s) == vectors.to_a.sort_by(&:to_s)

        initialize(to_h, order: order_array)
      end

      # Return the dataframe with rotate vectors positions, the vector at position count is now
      # the first vector of the dataframe.
      # If only one vector in the dataframe, the dataframe is return without any change.
      # @param count => Integer, the vector at position count will be the first vector of the dataframe.
      # @example
      #   df = DaruLite::DataFrame({
      #     a: [1, 2, 3],
      #     b: [4, 5, 6],
      #     total: [5, 7, 9],
      #   })
      #   df.rotate_vectors(-1)
      #   df
      #   # => #<DaruLite::DataFrame(3x3)>
      #   #       total b   a
      #   #   0   5     4   1
      #   #   1   7     5   2
      #   #   2   9     6   3
      def rotate_vectors(count = -1)
        return self unless vectors.many?

        self.order = vectors.to_a.rotate(count)
        self
      end

      # Sorts a dataframe (ascending/descending) in the given pripority sequence of
      # vectors, with or without a block.
      #
      # @param vector_order [Array] The order of vector names in which the DataFrame
      #   should be sorted.
      # @param opts [Hash] opts The options to sort with.
      # @option opts [TrueClass,FalseClass,Array] :ascending (true) Sort in ascending
      #   or descending order. Specify Array corresponding to *order* for multiple
      #   sort orders.
      # @option opts [Hash] :by (lambda{|a| a }) Specify attributes of objects to
      #   to be used for sorting, for each vector name in *order* as a hash of
      #   vector name and lambda expressions. In case a lambda for a vector is not
      #   specified, the default will be used.
      # @option opts [TrueClass,FalseClass,Array] :handle_nils (false) Handle nils
      #   automatically or not when a block is provided.
      #   If set to True, nils will appear at top after sorting.
      #
      # @example Sort a dataframe with a vector sequence.
      #
      #
      #   df = DaruLite::DataFrame.new({a: [1,2,1,2,3], b: [5,4,3,2,1]})
      #
      #   df.sort [:a, :b]
      #   # =>
      #   # <DaruLite::DataFrame:30604000 @name = d6a9294e-2c09-418f-b646-aa9244653444 @size = 5>
      #   #                   a          b
      #   #        2          1          3
      #   #        0          1          5
      #   #        3          2          2
      #   #        1          2          4
      #   #        4          3          1
      #
      # @example Sort a dataframe without a block. Here nils will be handled automatically.
      #
      #   df = DaruLite::DataFrame.new({a: [-3,nil,-1,nil,5], b: [4,3,2,1,4]})
      #
      #   df.sort([:a])
      #   # =>
      #   # <DaruLite::DataFrame:14810920 @name = c07fb5c7-2201-458d-b679-6a1f7ebfe49f @size = 5>
      #   #                    a          b
      #   #         1        nil          3
      #   #         3        nil          1
      #   #         0         -3          4
      #   #         2         -1          2
      #   #         4          5          4
      #
      # @example Sort a dataframe with a block with nils handled automatically.
      #
      #   df = DaruLite::DataFrame.new({a: [nil,-1,1,nil,-1,1], b: ['aaa','aa',nil,'baaa','x',nil] })
      #
      #   df.sort [:b], by: {b: lambda { |a| a.length } }
      #   # NoMethodError: undefined method `length' for nil:NilClass
      #   # from (pry):8:in `block in __pry__'
      #
      #   df.sort [:b], by: {b: lambda { |a| a.length } }, handle_nils: true
      #
      #   # =>
      #   # <DaruLite::DataFrame:28469540 @name = 5f986508-556f-468b-be0c-88cc3534445c @size = 6>
      #   #                    a          b
      #   #         2          1        nil
      #   #         5          1        nil
      #   #         4         -1          x
      #   #         1         -1         aa
      #   #         0        nil        aaa
      #   #         3        nil       baaa
      #
      # @example Sort a dataframe with a block with nils handled manually.
      #
      #   df = DaruLite::DataFrame.new({a: [nil,-1,1,nil,-1,1], b: ['aaa','aa',nil,'baaa','x',nil] })
      #
      #   # To print nils at the bottom one can use lambda { |a| (a.nil?)[1]:[0,a.length] }
      #   df.sort [:b], by: {b: lambda { |a| (a.nil?)?[1]:[0,a.length] } }, handle_nils: true
      #
      #   # =>
      #   #<DaruLite::DataFrame:22214180 @name = cd7703c7-1dca-4560-840b-5ea51a852ef9 @size = 6>
      #   #                 a          b
      #   #      4         -1          x
      #   #      1         -1         aa
      #   #      0        nil        aaa
      #   #      3        nil       baaa
      #   #      2          1        nil
      #   #      5          1        nil

      def sort!(vector_order, opts = {})
        raise ArgumentError, 'Required atleast one vector name' if vector_order.empty?

        # To enable sorting with categorical data,
        # map categories to integers preserving their order
        old = convert_categorical_vectors vector_order
        block = sort_prepare_block vector_order, opts

        order = @index.size.times.sort(&block)
        new_index = @index.reorder order

        # To reverse map mapping of categorical data to integers
        restore_categorical_vectors old

        @data.each do |vector|
          vector.reorder! order
        end

        self.index = new_index

        self
      end

      # Non-destructive version of #sort!
      def sort(vector_order, opts = {})
        dup.sort! vector_order, opts
      end

      private

      def convert_categorical_vectors(names)
        names.filter_map do |n|
          next unless self[n].category?

          old = [n, self[n]]
          self[n] = DaruLite::Vector.new(self[n].to_ints)
          old
        end
      end

      def restore_categorical_vectors(old)
        old.each { |name, vector| self[name] = vector }
      end

      def sort_build_row(vector_locs, by_blocks, ascending, handle_nils, r1, r2) # rubocop:disable  Metrics/ParameterLists
        # Create an array to be used for comparison of two rows in sorting
        vector_locs
          .zip(by_blocks, ascending, handle_nils)
          .map do |vector_loc, by, asc, handle_nil|
          value = @data[vector_loc].data[asc ? r1 : r2]

          if by
            value = begin
              by.call(value)
            rescue StandardError
              nil
            end
          end

          sort_handle_nils value, asc, handle_nil || !by
        end
      end

      def sort_handle_nils(value, asc, handle_nil)
        if !handle_nil
          value
        elsif asc
          [value.nil? ? 0 : 1, value]
        else
          [value.nil? ? 1 : 0, value]
        end
      end

      def sort_coerce_boolean(opts, symbol, default, size)
        val = opts[symbol]
        case val
        when true, false
          Array.new(size, val)
        when nil
          Array.new(size, default)
        when Array
          raise ArgumentError, "Specify same number of vector names and #{symbol}" if
            size != val.size

          val
        else
          raise ArgumentError, "Can't coerce #{symbol} from #{val.class} to boolean option"
        end
      end

      def sort_prepare_block(vector_order, opts)
        ascending   = sort_coerce_boolean opts, :ascending, true, vector_order.size
        handle_nils = sort_coerce_boolean opts, :handle_nils, false, vector_order.size

        by_blocks = vector_order.map { |v| (opts[:by] || {})[v] }
        vector_locs = vector_order.map { |v| @vectors[v] }

        lambda do |index1, index2|
          # Build left and right array to compare two rows
          left  = sort_build_row vector_locs, by_blocks, ascending, handle_nils, index1, index2
          right = sort_build_row vector_locs, by_blocks, ascending, handle_nils, index2, index1

          # Resolve conflict by Index if all attributes are same
          left  << index1
          right << index2
          left <=> right
        end
      end
    end
  end
end
