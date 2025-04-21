module DaruLite
  class Vector
    module Queryable
      def empty?
        @index.empty?
      end

      # Check if any one of mentioned values occur in the vector
      # @param values  [Array] values to check for
      # @return [true, false] returns true if any one of specified values
      #   occur in the vector
      # @example
      #   dv = DaruLite::Vector.new [1, 2, 3, 4, nil]
      #   dv.include_values? nil, Float::NAN
      #   # => true
      def include_values?(*values)
        values.any? { |v| include_with_nan? @data, v }
      end

      def any?(&)
        @data.data.any?(&)
      end

      def all?(&)
        @data.data.all?(&)
      end

      # Returns an array of either none or integer values, indicating the
      # +regexp+ matching with the given array.
      #
      # @param regexp [Regexp] A regular matching expression. For example, +/weeks/+.
      #
      # @return [Array] Containing either +nil+ or integer values, according to the match with the given +regexp+
      #
      # @example
      #   dv = DaruLite::Vector.new(['3 days', '5 weeks', '2 weeks'])
      #   dv.match(/weeks/)
      #
      #   # => [false, true, true]
      def match(regexp)
        @data.map { |value| !!(value =~ regexp) }
      end
    end
  end
end
