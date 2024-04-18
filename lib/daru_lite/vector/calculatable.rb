module DaruLite
  class Vector
    module Calculatable
      # Count the number of values specified
      # @param values [Array] values to count for
      # @return [Integer] the number of times the values mentioned occurs
      # @example
      #   dv = DaruLite::Vector.new [1, 2, 1, 2, 3, 4, nil, nil]
      #   dv.count_values nil
      #   # => 2
      def count_values(*values)
        positions(*values).size
      end

      # Create a summary of the Vector
      # @param indent_level [Fixnum] indent level
      # @return [String] String containing the summary of the Vector
      # @example
      #   dv = DaruLite::Vector.new [1, 2, 3]
      #   puts dv.summary
      #
      #   # =
      #   #   n :3
      #   #   non-missing:3
      #   #   median: 2
      #   #   mean: 2.0000
      #   #   std.dev.: 1.0000
      #   #   std.err.: 0.5774
      #   #   skew: 0.0000
      #   #   kurtosis: -2.3333
      def summary(indent_level = 0)
        non_missing = size - count_values(*DaruLite::MISSING_VALUES)
        summary = ('  =' * indent_level) + "= #{name}" \
                                           "\n  n :#{size}" \
                                           "\n  non-missing:#{non_missing}"
        case type
        when :object
          summary << object_summary
        when :numeric
          summary << numeric_summary
        end
        summary.split("\n").join("\n#{'  ' * indent_level}")
      end

      # Displays summary for an object type Vector
      # @return [String] String containing object vector summary
      def object_summary
        nval = count_values(*DaruLite::MISSING_VALUES)
        summary = "\n  factors: #{factors.to_a.join(',')}" \
                  "\n  mode: #{mode.to_a.join(',')}" \
                  "\n  Distribution\n"

        data = frequencies.sort.each_with_index.map do |v, k|
          [k, v, format('%0.2f%%', ((nval.zero? ? 1 : v.quo(nval)) * 100))]
        end

        summary + Formatters::Table.format(data)
      end

      # Displays summary for an numeric type Vector
      # @return [String] String containing numeric vector summary
      def numeric_summary
        summary = "\n  median: #{median}" +
                  format("\n  mean: %0.4f", mean)
        if sd
          summary << (format("\n  std.dev.: %0.4f", sd) +
                    format("\n  std.err.: %0.4f", se))
        end

        if count_values(*DaruLite::MISSING_VALUES).zero?
          summary << (format("\n  skew: %0.4f", skew) +
                    format("\n  kurtosis: %0.4f", kurtosis))
        end
        summary
      end
    end
  end
end
