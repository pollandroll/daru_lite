module DaruLite
  module Maths
    module Statistics
      module Vector
        # Largest and smallest values, and where they are.
        module Extrema
          # Returns the maximum value(s) present in the vector, with an optional comparator block.
          #
          # @param size [Integer] Number of maximum values to return. Defaults to nil.
          #
          # @example
          #
          #   dv = DaruLite::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]),
          #                             index: DaruLite::Index.new([:t, :d, :j])
          #   #=>
          #   #   #<DaruLite::Vector(3)>
          #   #       t   Tyrion
          #   #       d   Daenerys
          #   #       j   Jon Starkgaryen
          #
          #   dv.max
          #   #=> "Tyrion"
          #
          #   dv.max(2) { |a,b| a.size <=> b.size }
          #   #=> ["Jon Starkgaryen","Daenerys"]
          def max(size = nil, &)
            reject_values(*DaruLite::MISSING_VALUES).to_a.max(size, &)
          end

          # Returns the maximum value(s) present in the vector, with a compulsory object block.
          #
          # @param size [Integer] Number of maximum values to return. Defaults to nil.
          #
          # @example
          #
          #   dv = DaruLite::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]),
          #                             index: DaruLite::Index.new([:t, :d, :j])
          #   #=>
          #   #   #<DaruLite::Vector(3)>
          #   #       t   Tyrion
          #   #       d   Daenerys
          #   #       j   Jon Starkgaryen
          #
          #   dv.max_by(2) { |i| i.size }
          #   #=> ["Jon Starkgaryen","Daenerys"]
          def max_by(size = nil, &block)
            raise ArgumentError, 'Expected compulsory object block in max_by method' unless block

            reject_values(*DaruLite::MISSING_VALUES).to_a.max_by(size, &block)
          end

          # Returns the minimum value(s) present in the vector, with an optional comparator block.
          #
          # @param size [Integer] Number of minimum values to return. Defaults to nil.
          #
          # @example
          #
          #   dv = DaruLite::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]),
          #                             index: DaruLite::Index.new([:t, :d, :j])
          #   #=>
          #   #   #<DaruLite::Vector(3)>
          #   #       t   Tyrion
          #   #       d   Daenerys
          #   #       j   Jon Starkgaryen
          #
          #   dv.min
          #   #=> "Daenerys"
          #
          #   dv.min(2) { |a,b| a.size <=> b.size }
          #   #=> ["Tyrion","Daenerys"]
          def min(size = nil, &)
            reject_values(*DaruLite::MISSING_VALUES).to_a.min(size, &)
          end

          # Returns the minimum value(s) present in the vector, with a compulsory object block.
          #
          # @param size [Integer] Number of minimum values to return. Defaults to nil.
          #
          # @example
          #
          #   dv = DaruLite::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]),
          #                             index: DaruLite::Index.new([:t, :d, :j])
          #   #=>
          #   #   #<DaruLite::Vector(3)>
          #   #       t   Tyrion
          #   #       d   Daenerys
          #   #       j   Jon Starkgaryen
          #
          #   dv.min_by(2) { |i| i.size }
          #   #=> ["Tyrion","Daenerys"]
          def min_by(size = nil, &block)
            raise ArgumentError, 'Expected compulsory object block in min_by method' unless block

            reject_values(*DaruLite::MISSING_VALUES).to_a.min_by(size, &block)
          end

          # Returns the index of the maximum value(s) present in the vector, with an optional
          # comparator block.
          #
          # @param size [Integer] Number of maximum indices to return. Defaults to nil.
          #
          # @example
          #
          #   dv = DaruLite::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]),
          #                             index: DaruLite::Index.new([:t, :d, :j])
          #   #=>
          #   #   #<DaruLite::Vector(3)>
          #   #       t   Tyrion
          #   #       d   Daenerys
          #   #       j   Jon Starkgaryen
          #
          #   dv.index_of_max
          #   #=> :t
          #
          #   dv.index_of_max(2) { |a,b| a.size <=> b.size }
          #   #=> [:j, :d]
          def index_of_max(size = nil, &)
            vals = max(size, &)
            indexes_of_values(vals)
          end

          # Returns the index of the maximum value(s) present in the vector, with a compulsory
          # object block.
          #
          # @param size [Integer] Number of maximum indices to return. Defaults to nil.
          #
          # @example
          #
          #   dv = DaruLite::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]),
          #                             index: DaruLite::Index.new([:t, :d, :j])
          #   #=>
          #   #   #<DaruLite::Vector(3)>
          #   #       t   Tyrion
          #   #       d   Daenerys
          #   #       j   Jon Starkgaryen
          #
          #   dv.index_of_max_by(2) { |i| i.size }
          #   #=> [:j, :d]
          def index_of_max_by(size = nil, &)
            vals = max_by(size, &)
            indexes_of_values(vals)
          end

          # Returns the index of the minimum value(s) present in the vector, with an optional
          # comparator block.
          #
          # @param size [Integer] Number of minimum indices to return. Defaults to nil.
          #
          # @example
          #
          #   dv = DaruLite::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]),
          #                             index: DaruLite::Index.new([:t, :d, :j])
          #   #=>
          #   #   #<DaruLite::Vector(3)>
          #   #       t   Tyrion
          #   #       d   Daenerys
          #   #       j   Jon Starkgaryen
          #
          #   dv.index_of_min
          #   #=> :d
          #
          #   dv.index_of_min(2) { |a,b| a.size <=> b.size }
          #   #=> [:t, :d]
          def index_of_min(size = nil, &)
            vals = min(size, &)
            indexes_of_values(vals)
          end

          # Returns the index of the minimum value(s) present in the vector, with a compulsory
          # object block.
          #
          # @param size [Integer] Number of minimum indices to return. Defaults to nil.
          #
          # @example
          #
          #   dv = DaruLite::Vector.new (["Tyrion", "Daenerys", "Jon Starkgaryen"]),
          #                             index: DaruLite::Index.new([:t, :d, :j])
          #   #=>
          #   #   #<DaruLite::Vector(3)>
          #   #       t   Tyrion
          #   #       d   Daenerys
          #   #       j   Jon Starkgaryen
          #
          #   dv.index_of_min(2) { |i| i.size }
          #   #=> [:t, :d]
          def index_of_min_by(size = nil, &)
            vals = min_by(size, &)
            indexes_of_values(vals)
          end

          # Return the maximum element present in the Vector, as a Vector.
          # @return [DaruLite::Vector]
          def max_index
            max_value = @data.max
            DaruLite::Vector.new({ index_of(max_value) => max_value }, name: @name, dtype: @dtype)
          end

          private

          # Map each value to the index of a distinct non-missing element, so tied
          # values get different indexes.
          def indexes_of_values(vals)
            dv = reject_values(*DaruLite::MISSING_VALUES)
            return dv.index_of(vals) unless vals.is_a?(Array)

            remaining = dv.index.to_a.zip(dv.to_a)
            vals.map { |val| remaining.delete_at(remaining.index { |_, v| v == val }).first }
          end
        end
      end
    end
  end
end
