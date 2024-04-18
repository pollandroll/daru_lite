module DaruLite
  class Vector
    module Joinable
      # Append an element to the vector by specifying the element and index
      def concat(element, index)
        raise IndexError, 'Expected new unique index' if @index.include? index

        @index |= [index]
        @data[@index[index]] = element

        update_position_cache
      end
      alias push concat
      alias << concat
    end
  end
end
