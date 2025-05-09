module DaruLite
  module Accessors
    # Internal class for wrapping ruby array
    class ArrayWrapper
      include Enumerable
      extend ::Forwardable

      def_delegators :@data, :slice!

      def each(&)
        @data.each(&)
        self
      end

      def map!(&)
        @data.map!(&)
        self
      end

      attr_accessor :size
      attr_reader   :data

      def initialize(vector, context)
        @data = vector.to_a
        @context = context

        set_size
      end

      def [](*index)
        @data[*index]
      end

      def []=(index, value)
        @data[index] = value
        set_size
      end

      def ==(other)
        @data == other
      end

      def delete_at(index)
        @data.delete_at index
        set_size
      end

      def index(...)
        @data.index(...)
      end

      def <<(element)
        @data << element
        set_size
      end

      def fill(*arg)
        @data.fill(*arg)
        set_size
      end

      def uniq
        @data.uniq
      end

      def to_a
        @data
      end

      def dup
        ArrayWrapper.new @data.dup, @context
      end

      def compact
        @data - DaruLite::MISSING_VALUES
      end

      def mean
        values_to_sum = compact
        return if values_to_sum.empty?

        values_to_sum.sum.quo(values_to_sum.size).to_f
      end

      def product
        compact.inject :*
      end

      def max
        compact.max
      end

      def min
        compact.min
      end

      def sum
        values_to_sum = compact
        values_to_sum.sum if values_to_sum.any?
      end

      private

      def set_size
        @size = @data.size
      end
    end
  end
end
