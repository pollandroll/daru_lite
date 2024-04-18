module DaruLite
  class Vector
    module Filterable
      # Return a new vector based on the contents of a boolean array. Use with the
      # comparator methods to obtain meaningful results. See this notebook for
      # a good overview of using #where.
      #
      # @param bool_array [DaruLite::Core::Query::BoolArray, Array<TrueClass, FalseClass>] The
      #   collection containing the true of false values. Each element in the Vector
      #   corresponding to a `true` in the bool_arry will be returned alongwith it's
      #   index.
      # @example Usage of #where.
      #   vector = DaruLite::Vector.new([2,4,5,51,5,16,2,5,3,2,1,5,2,5,2,1,56,234,6,21])
      #
      #   # Simple logic statement passed to #where.
      #   vector.where(vector.eq(5).or(vector.eq(1)))
      #   # =>
      #   ##<DaruLite::Vector:77626210 @name = nil @size = 7 >
      #   #    nil
      #   #  2   5
      #   #  4   5
      #   #  7   5
      #   # 10   1
      #   # 11   5
      #   # 13   5
      #   # 15   1
      #
      #   # A somewhat more complex logic statement
      #   vector.where((vector.eq(5) | vector.lteq(1)) & vector.in([4,5,1]))
      #   #=>
      #   ##<DaruLite::Vector:81072310 @name = nil @size = 7 >
      #   #    nil
      #   #  2   5
      #   #  4   5
      #   #  7   5
      #   # 10   1
      #   # 11   5
      #   # 13   5
      #   # 15   1
      def where(bool_array)
        DaruLite::Core::Query.vector_where self, bool_array
      end

      # Return a new vector based on the contents of a boolean array and &block.
      #
      # @param bool_array [DaruLite::Core::Query::BoolArray, Array<TrueClass, FalseClass>, &block] The
      #   collection containing the true of false values. Each element in the Vector
      #   corresponding to a `true` in the bool_array will be returned along with it's
      #   index. The &block may contain manipulative functions for the Vector elements.
      #
      # @return [DaruLite::Vector]
      #
      # @example Usage of #apply_where.
      #   dv = DaruLite::Vector.new ['3 days', '5 weeks', '2 weeks']
      #   dv = dv.apply_where(dv.match /weeks/) { |x| "#{x.split.first.to_i * 7} days" }
      #   # =>
      #   ##<DaruLite::Vector(3)>
      #   #  0   3 days
      #   #  1   35 days
      #   #  2   14 days
      def apply_where(bool_array, &block)
        DaruLite::Core::Query.vector_apply_where self, bool_array, &block
      end

      # Keep only unique elements of the vector alongwith their indexes.
      def uniq
        uniq_vector = @data.uniq
        new_index   = uniq_vector.map { |element| index_of(element) }

        DaruLite::Vector.new uniq_vector, name: @name, index: new_index, dtype: @dtype
      end

      # Delete an element if block returns true. Destructive.
      def delete_if
        return to_enum(:delete_if) unless block_given?

        keep_e, keep_i = each_with_index.reject { |n, _i| yield(n) }.transpose

        @data = cast_vector_to @dtype, keep_e
        @index = DaruLite::Index.new(keep_i)

        update_position_cache

        self
      end

      # Keep an element if block returns true. Destructive.
      def keep_if
        return to_enum(:keep_if) unless block_given?

        delete_if { |val| !yield(val) }
      end

      # Return a vector with specified values removed
      # @param values [Array] values to reject from resultant vector
      # @return [DaruLite::Vector] vector with specified values removed
      # @example
      #   dv = DaruLite::Vector.new [1, 2, nil, Float::NAN]
      #   dv.reject_values nil, Float::NAN
      #   # => #<DaruLite::Vector(2)>
      #   #   0   1
      #   #   1   2
      def reject_values(*values)
        resultant_pos = size.times.to_a - positions(*values)
        dv = at(*resultant_pos)
        # Handle the case when number of positions is 1
        # and hence #at doesn't return a vector
        if dv.is_a?(DaruLite::Vector)
          dv
        else
          pos = resultant_pos.first
          at(pos..pos)
        end
      end

      # Returns a Vector with only numerical data. Missing data is included
      # but non-Numeric objects are excluded. Preserves index.
      def only_numerics
        numeric_indexes =
          each_with_index
          .select { |v, _i| v.is_a?(Numeric) || v.nil? }
          .map(&:last)

        self[*numeric_indexes]
      end
    end
  end
end
