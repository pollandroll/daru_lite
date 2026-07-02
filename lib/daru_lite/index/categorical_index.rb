module DaruLite
  class CategoricalIndex < Index
    UNSUPPORTED_RANGE_MSG =
      'CategoricalIndex does not support label-range slicing: ' \
      'categories are unordered and may repeat'.freeze

    # Create a categorical index object.
    # @param indexes [Array<object>] array of indexes
    # @return [DaruLite::CategoricalIndex] categorical index
    # @example
    #   DaruLite::CategoricalIndex.new [:a, 1, :a, 1, :c]
    #   # => #<DaruLite::CategoricalIndex(5): {a, 1, a, 1, c}>
    def initialize(indexes)
      # Create a hash to map each category to positional indexes
      categories = indexes.each_with_index.group_by(&:first)
      @cat_hash = categories.transform_values { |group| group.map(&:last) }

      # Map each category to a unique integer for effective storage in @array
      map_cat_int = categories.keys.each_with_index.to_h

      # To link every instance to its category,
      # it stores integer for every instance representing its category
      @array = map_cat_int.values_at(*indexes)
    end

    # Duplicates the index object and return it
    # @return [DaruLite::CategoricalIndex] duplicated index object
    def dup
      # Improve it by intializing index by hash
      DaruLite::CategoricalIndex.new to_a
    end

    # Returns true index or category is valid
    # @param index [object] the index value to look for
    # @return [true, false] true if index is included, false otherwise
    def include?(index)
      @cat_hash.include? index
    end

    # Returns array of categories
    # @example
    #   x = DaruLite::CategoricalIndex.new [:a, 1, :a, 1, :c]
    #   x.categories
    #   # => [:a, 1, :c]
    def categories
      @cat_hash.keys
    end

    # Returns positions given categories or positions
    # @note If the argument does not a valid category it treats it as position
    #   value and return it as it is.
    # @param indexes [Array<object>] categories or positions
    # @example
    #   x = DaruLite::CategoricalIndex.new [:a, 1, :a, 1, :c]
    #   x.pos :a, 1
    #   # => [0, 1, 2, 3]
    def pos(*indexes)
      raise ArgumentError, UNSUPPORTED_RANGE_MSG if indexes.any?(Range)

      positions = indexes.map do |index|
        if include? index
          @cat_hash[index]
        elsif index.is_a?(Numeric) && index < @array.size
          index
        else
          raise IndexError, "#{index.inspect} is neither a valid category nor a valid position"
        end
      end

      positions.flatten!
      positions.size == 1 ? positions.first : positions.sort
    end

    # Returns the position(s) of the given category/categories or position(s).
    # Mirrors Index#[] but resolves against the categorical structure
    # (@cat_hash / @array) instead of @relation_hash, which CategoricalIndex
    # never populates.
    # @param keys [Array<object>] categories or positions to look up
    # @return [Integer, Array<Integer>, nil] position(s), or nil if absent
    # @example
    #   idx = DaruLite::CategoricalIndex.new [:a, :b, :a]
    #   idx[:b]   # => 1
    #   idx[:z]   # => nil
    def [](*keys)
      pos(*keys)
    rescue IndexError
      nil
    end

    # Returns the category located at a positional value.
    # Mirrors Index#key but reads the categorical structure instead of @keys,
    # which CategoricalIndex never populates.
    # @param value [Integer] positional value
    # @return [object, nil] category at the position, or nil if out of range
    # @example
    #   idx = DaruLite::CategoricalIndex.new [:a, :b, :a]
    #   idx.key 1   # => :b
    #   idx.key 99  # => nil
    def key(value)
      return nil unless value.is_a?(Numeric)

      to_a[value]
    end

    # Label-range slicing is not supported: categories are unordered and may
    # repeat, so a range of positions between two labels is ambiguous.
    # @raise [NotImplementedError] always
    def slice(*)
      raise NotImplementedError, UNSUPPORTED_RANGE_MSG
    end

    # Label-range slicing is not supported: categories are unordered and may
    # repeat, so a range of positions between two labels is ambiguous.
    # @raise [NotImplementedError] always
    def subset_slice(*)
      raise NotImplementedError, UNSUPPORTED_RANGE_MSG
    end

    # Returns index value from position
    # @param pos [Integer] the position to look for
    # @return [object] category corresponding to position
    # @example
    #   idx = DaruLite::CategoricalIndex.new [:a, :b, :a, :b, :c]
    #   idx.index_from_pos 1
    #   # => :b
    def index_from_pos(pos)
      cat_from_int @array[pos]
    end

    # Returns enumerator enumerating all index values in the order they occur
    # @return [Enumerator] all index values
    # @example
    #   idx = DaruLite::CategoricalIndex.new [:a, :a, :b]
    #   idx.each.to_a
    #   # => [:a, :a, :b]
    def each
      return enum_for(:each) unless block_given?

      @array.each { |pos| yield cat_from_int pos }
      self
    end

    # Compares two index object. Returns true if every instance of category
    # occur at the same position
    # @param [DaruLite::CateogricalIndex] other index object to be checked against
    # @return [true, false] true if other is similar to self
    # @example
    #   a = DaruLite::CategoricalIndex.new [:a, :a, :b]
    #   b = DaruLite::CategoricalIndex.new [:b, :a, :a]
    #   a == b
    #   # => false
    def ==(other)
      self.class == other.class &&
        size == other.size &&
        to_h == other.to_h
    end

    # Returns all the index values
    # @return [Array] all index values
    # @example
    #   idx = DaruLite::CategoricalIndex.new [:a, :b, :a]
    #   idx.to_a
    def to_a
      each.to_a
    end

    # Returns hash table mapping category to positions at which they occur
    # @return [Hash] hash table mapping category to array of positions
    # @example
    #   idx = DaruLite::CategoricalIndex.new [:a, :b, :a]
    #   idx.to_h
    #   # => {:a=>[0, 2], :b=>[1]}
    def to_h
      @cat_hash
    end

    # Returns size of the index object
    # @return [Integer] total number of instances of all categories
    # @example
    #   idx = DaruLite::CategoricalIndex.new [:a, :b, :a]
    #   idx.size
    #   # => 3
    def size
      @array.size
    end

    # Returns true if index object is storing no category
    # @return [true, false] true if index object is empty
    # @example
    #   i = DaruLite::CategoricalIndex.new []
    #   # => #<DaruLite::CategoricalIndex(0): {}>
    #   i.empty?
    #   # => true
    def empty?
      @array.empty?
    end

    # Return subset given categories or positions
    # @param indexes [Array<object>] categories or positions
    # @return [DaruLite::CategoricalIndex] subset of the self containing the
    #   mentioned categories or positions
    # @example
    #   idx = DaruLite::CategoricalIndex.new [:a, :b, :a, :b, :c]
    #   idx.subset :a, :b
    #   # => #<DaruLite::CategoricalIndex(4): {a, b, a, b}>
    def subset(*indexes)
      positions = pos(*indexes)
      new_index = positions.map { |pos| index_from_pos pos }

      DaruLite::CategoricalIndex.new new_index.flatten
    end

    # Takes positional values and returns subset of the self
    #   capturing the categories at mentioned positions
    # @param positions [Array<Integer>] positional values
    # @return [object] index object
    # @example
    #   idx = DaruLite::CategoricalIndex.new [:a, :b, :a, :b, :c]
    #   idx.at 0, 1
    #   # => #<DaruLite::CategoricalIndex(2): {a, b}>
    def at(*positions)
      positions = preprocess_positions(*positions)
      validate_positions(*positions)
      if positions.is_a? Integer
        index_from_pos(positions)
      else
        DaruLite::CategoricalIndex.new(positions.map { |p| index_from_pos(p) })
      end
    end

    # Add specified index values to the index object
    # @param indexes [Array<object>] index values to add
    # @return [DaruLite::CategoricalIndex] index object with added values
    # @example
    #   idx = DaruLite::CategoricalIndex.new [:a, :b, :a, :b, :c]
    #   idx.add :d
    #   # => #<DaruLite::CategoricalIndex(6): {a, b, a, b, c, d}>
    def add(*indexes)
      DaruLite::CategoricalIndex.new(to_a + indexes)
    end

    private

    # Single-key position lookup, resolved against the categorical structure.
    # Overrides Index#numeric_pos, which reads the never-populated @relation_hash.
    # @raise [IndexError] when the key is neither a valid category nor position
    def numeric_pos(key)
      pos(key)
    end

    # Label-range slicing is not supported (see #slice / #subset_slice).
    # @raise [NotImplementedError] always
    def preprocess_range(_rng)
      raise NotImplementedError, UNSUPPORTED_RANGE_MSG
    end

    def int_from_cat(cat)
      @cat_hash.keys.index cat
    end

    def cat_from_int(cat)
      @cat_hash.keys[cat]
    end
  end
end
