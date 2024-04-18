module DaruLite
  class Vector
    module Duplicatable
      # Duplicated a vector
      # @return [DaruLite::Vector] duplicated vector
      def dup
        DaruLite::Vector.new @data.dup, name: @name, index: @index.dup
      end

      # Copies the structure of the vector (i.e the index, size, etc.) and fills all
      # all values with nils.
      def clone_structure
        DaruLite::Vector.new(([nil] * size), name: @name, index: @index.dup)
      end
    end
  end
end
