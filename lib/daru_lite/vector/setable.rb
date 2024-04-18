module DaruLite
  class Vector
    module Setable
      # Change value at given positions
      # @param positions [Array<object>] positional values
      # @param [object] val value to assign
      # @example
      #   dv = DaruLite::Vector.new 'a'..'e'
      #   dv.set_at [0, 1], 'x'
      #   dv
      #   # => #<DaruLite::Vector(5)>
      #   #   0   x
      #   #   1   x
      #   #   2   c
      #   #   3   d
      #   #   4   e
      def set_at(positions, val)
        validate_positions(*positions)
        positions.map { |pos| @data[pos] = val }
        update_position_cache
      end

      # Just like in Hashes, you can specify the index label of the DaruLite::Vector
      # and assign an element an that place in the DaruLite::Vector.
      #
      # == Usage
      #
      #   v = DaruLite::Vector.new([1,2,3], index: [:a, :b, :c])
      #   v[:a] = 999
      #   #=>
      #   ##<DaruLite::Vector:90257920 @name = nil @size = 3 >
      #   #    nil
      #   #  a 999
      #   #  b   2
      #   #  c   3
      def []=(*indexes, val)
        cast(dtype: :array) if val.nil? && dtype != :array

        guard_type_check(val)

        modify_vector(indexes, val)

        update_position_cache
      end
    end
  end
end
