module DaruLite
  class Vector
    module Indexable
      # Get index of element
      def index_of(element)
        case dtype
        when :array then @index.key(@data.index { |x| x.eql? element })
        else @index.key @data.index(element)
        end
      end

      def reset_index!
        @index = DaruLite::Index.new(Array.new(size) { |i| i })
        self
      end

      # Returns *true* if an index exists
      def has_index?(index) # rubocop:disable Naming/PredicateName
        @index.include? index
      end

      def detach_index
        DaruLite::DataFrame.new(
          index: @index.to_a,
          values: @data.to_a
        )
      end

      # Sets new index for vector. Preserves index->value correspondence.
      # Sets nil for new index keys absent from original index.
      # @note Unlike #reorder! which takes positions as input it takes
      #   index as an input to reorder the vector
      # @param [DaruLite::Index, DaruLite::MultiIndex] new_index new index to order with
      # @return [DaruLite::Vector] vector reindexed with new index
      def reindex!(new_index)
        values = []
        each_with_index do |val, i|
          values[new_index[i]] = val if new_index.include?(i)
        end
        values.fill(nil, values.size, new_index.size - values.size)

        @data = cast_vector_to @dtype, values
        @index = new_index

        update_position_cache

        self
      end

      # Create a new vector with a different index, and preserve the indexing of
      # current elements.
      def reindex(new_index)
        dup.reindex!(new_index)
      end

      def index=(idx)
        idx = Index.coerce(idx)

        raise ArgumentError, "Size of supplied index #{idx.size} does not match size of Vector" if idx.size != size
        raise ArgumentError, 'Can only assign type Index and its subclasses.' unless idx.is_a?(DaruLite::Index)

        @index = idx
      end

      # Return indexes of values specified
      # @param values [Array] values to find indexes for
      # @return [Array] array of indexes of values specified
      # @example
      #   dv = DaruLite::Vector.new [1, 2, nil, Float::NAN], index: 11..14
      #   dv.indexes nil, Float::NAN
      #   # => [13, 14]
      def indexes(*values)
        index.to_a.values_at(*positions(*values))
      end
    end
  end
end
