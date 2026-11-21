module DaruLite
  class Vector
    module Convertible
      # @return [DaruLite::DataFrame] the vector as a single-vector dataframe
      def to_df
        DaruLite::DataFrame.new({ @name => @data }, name: @name, index: @index)
      end

      # Convert Vector to a horizontal or vertical Ruby Matrix.
      #
      # == Arguments
      #
      # * +axis+ - Specify whether you want a *:horizontal* or a *:vertical* matrix.
      def to_matrix(axis = :horizontal)
        case axis
        when :horizontal
          Matrix[to_a]
        when :vertical
          Matrix.columns([to_a])
        else
          raise ArgumentError, "axis should be either :horizontal or :vertical, not #{axis}"
        end
      end

      # Convert to hash (explicit). Hash keys are indexes and values are the correspoding elements
      def to_h
        @index.to_h { |index| [index, self[index]] }
      end

      # Return an array
      def to_a
        @data.to_a
      end

      # Convert the hash from to_h to json
      def to_json(*)
        to_h.to_json
      end

      def to_s
        "#<#{self.class}#{": #{@name}" if @name}(#{size})#{':category' if category?}>"
      end
    end
  end
end
