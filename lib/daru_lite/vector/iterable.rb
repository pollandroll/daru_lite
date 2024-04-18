module DaruLite
  class Vector
    module Iterable
      def each(&block)
        return to_enum(:each) unless block

        @data.each(&block)
        self
      end

      def each_index(&block)
        return to_enum(:each_index) unless block

        @index.each(&block)
        self
      end

      def each_with_index(&block)
        return to_enum(:each_with_index) unless block

        @data.to_a.zip(@index.to_a).each(&block)

        self
      end

      def map!(&block)
        return to_enum(:map!) unless block

        @data.map!(&block)
        self
      end

      # Like map, but returns a DaruLite::Vector with the returned values.
      def recode(dt = nil, &block)
        return to_enum(:recode, dt) unless block

        dup.recode! dt, &block
      end

      # Destructive version of recode!
      def recode!(dt = nil, &block)
        return to_enum(:recode!, dt) unless block

        @data.map!(&block).data
        @data = cast_vector_to(dt || @dtype)
        self
      end

      # Reports all values that doesn't comply with a condition.
      # Returns a hash with the index of data and the invalid data.
      def verify
        (0...size)
          .map { |i| [i, @data[i]] }
          .reject { |_i, val| yield(val) }
          .to_h
      end

      def apply_method(method, keys: nil, by_position: true)
        vect = keys ? get_sub_vector(keys, by_position: by_position) : self

        case method
        when Symbol then vect.send(method)
        when Proc   then method.call(vect)
        else raise
        end
      end
      alias apply_method_on_sub_vector apply_method

      # Replaces specified values with a new value
      # @param [Array] old_values array of values to replace
      # @param [object] new_value new value to replace with
      # @note It performs the replace in place.
      # @return [DaruLite::Vector] Same vector itself with values
      #   replaced with new value
      # @example
      #   dv = DaruLite::Vector.new [1, 2, :a, :b]
      #   dv.replace_values [:a, :b], nil
      #   dv
      #   # =>
      #   # #<DaruLite::Vector:19903200 @name = nil @metadata = {} @size = 4 >
      #   #     nil
      #   #   0   1
      #   #   1   2
      #   #   2 nil
      #   #   3 nil
      def replace_values(old_values, new_value)
        old_values = [old_values] unless old_values.is_a? Array
        size.times do |pos|
          set_at([pos], new_value) if include_with_nan? old_values, at(pos)
        end
        self
      end
    end
  end
end
