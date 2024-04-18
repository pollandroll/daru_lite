module DaruLite
  class Vector
    module Sortable
      # Sorts a vector according to its values. If a block is specified, the contents
      # will be evaluated and data will be swapped whenever the block evaluates
      # to *true*. Defaults to ascending order sorting. Any missing values will be
      # put at the end of the vector. Preserves indexing. Default sort algorithm is
      # quick sort.
      #
      # == Options
      #
      # * +:ascending+ - if false, will sort in descending order. Defaults to true.
      #
      # * +:type+ - Specify the sorting algorithm. Only supports quick_sort for now.
      # == Usage
      #
      #   v = DaruLite::Vector.new ["My first guitar", "jazz", "guitar"]
      #   # Say you want to sort these strings by length.
      #   v.sort(ascending: false) { |a,b| a.length <=> b.length }
      def sort(opts = {}, &block)
        opts = { ascending: true }.merge(opts)

        vector_index = resort_index(@data.each_with_index, opts, &block)
        vector, index = vector_index.transpose

        index = @index.reorder index

        DaruLite::Vector.new(vector, index: index, name: @name, dtype: @dtype)
      end

      # Sorts the vector according to it's`Index` values. Defaults to ascending
      # order sorting.
      #
      # @param [Hash] opts the options for sort_by_index method.
      # @option opts [Boolean] :ascending false, will sort `index` in
      #  descending order.
      #
      # @return [Vector] new sorted `Vector` according to the index values.
      #
      # @example
      #
      #   dv = DaruLite::Vector.new [11, 13, 12], index: [23, 21, 22]
      #   # Say you want to sort index in ascending order
      #   dv.sort_by_index(ascending: true)
      #   #=> DaruLite::Vector.new [13, 12, 11], index: [21, 22, 23]
      #   # Say you want to sort index in descending order
      #   dv.sort_by_index(ascending: false)
      #   #=> DaruLite::Vector.new [11, 12, 13], index: [23, 22, 21]
      def sort_by_index(opts = {})
        opts = { ascending: true }.merge(opts)
        _, new_order = resort_index(@index.each_with_index, opts).transpose

        reorder new_order
      end

      DEFAULT_SORTER = lambda { |(lv, li), (rv, ri)|
        if lv.nil? && rv.nil?
          li <=> ri
        elsif lv.nil?
          -1
        elsif rv.nil?
          1
        else
          lv <=> rv
        end
      }

      # Just sort the data and get an Array in return using Enumerable#sort.
      # Non-destructive.
      # :nocov:
      def sorted_data(&block)
        @data.to_a.sort(&block)
      end
      # :nocov:

      # Reorder the vector with given positions
      # @note Unlike #reindex! which takes index as input, it takes
      #   positions as an input to reorder the vector
      # @param [Array] order the order to reorder the vector with
      # @return reordered vector
      # @example
      #   dv = DaruLite::Vector.new [3, 2, 1], index: ['c', 'b', 'a']
      #   dv.reorder! [2, 1, 0]
      #   # => #<DaruLite::Vector(3)>
      #   #   a   1
      #   #   b   2
      #   #   c   3
      def reorder!(order)
        @index = @index.reorder order
        data_array = order.map { |i| @data[i] }
        @data = cast_vector_to @dtype, data_array, @nm_dtype
        update_position_cache
        self
      end

      # Non-destructive version of #reorder!
      def reorder(order)
        dup.reorder! order
      end

      private

      def resort_index(vector_index, opts)
        if block_given?
          vector_index.sort { |(lv, _li), (rv, _ri)| yield(lv, rv) }
        else
          vector_index.sort(&DEFAULT_SORTER)
        end
          .tap { |res| res.reverse! unless opts[:ascending] }
      end
    end
  end
end
