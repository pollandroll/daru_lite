module DaruLite
  class Index # rubocop:disable Metrics/ClassLength
    include Enumerable
    # It so happens that over riding the .new method in a super class also
    # tampers with the default .new method for class that inherit from the
    # super class (Index in this case). Thus we first alias the original
    # new method (from Object) to __new__ when the Index class is evaluated,
    # and then we use an inherited hook such that the old new method (from
    # Object) is once again the default .new for the subclass.
    # Refer http://blog.sidu.in/2007/12/rubys-new-as-factory.html
    class << self
      alias __new__ new

      def inherited(subclass)
        class << subclass
          alias_method :new, :__new__
        end
      end
    end

    # We over-ride the .new method so that any sort of Index can be generated
    # from DaruLite::Index based on the types of arguments supplied.
    def self.new(*args, &)
      # FIXME: I'm not sure this clever trick really deserves our attention.
      # Most of common ruby libraries just avoid it in favor of usual
      # factor method, like `Index.create`. When `Index.new(...).class != Index`
      # it just leads to confusion and surprises. - zverok, 2016-05-18
      source = args.first

      MultiIndex.try_from_tuples(source) ||
        DateTimeIndex.try_create(source) ||
        allocate.tap { |i| i.send(:initialize, *args, &) }
    end

    def self.coerce(maybe_index)
      maybe_index.is_a?(Index) ? maybe_index : DaruLite::Index.new(maybe_index)
    end

    def each(&block)
      return to_enum(:each) unless block

      @relation_hash.each_key(&block)
      self
    end

    attr_reader :relation_hash, :size
    attr_accessor :name

    # @example
    #
    #   idx = DaruLite::Index.new [:one, 'one', 1, 2, :two]
    #   => #<DaruLite::Index(5): {one, one, 1, 2, two}>
    #
    #   # set the name
    #
    #   idx.name = "index_name"
    #   => "index_name"
    #
    #   idx
    #   => #<DaruLite::Index(5): index_name {one, one, 1, 2, two}>
    #
    #   # set the name during initialization
    #
    #   idx = DaruLite::Index.new [:one, 'one', 1, 2, :two], name: "index_name"
    #   => #<DaruLite::Index(5): index_name {one, one, 1, 2, two}>
    def initialize(index, opts = {})
      index = guess_index index
      @relation_hash = index.each_with_index.to_h.freeze
      @keys = @relation_hash.keys
      @size = @relation_hash.size
      @name = opts[:name]
    end

    def ==(other)
      return false if self.class != other.class || other.size != @size

      @keys == other.to_a &&
        @relation_hash.values == other.relation_hash.values
    end

    def [](key, *rest)
      if key.is_a?(Range)
        by_range key
      elsif !rest.empty?
        by_multi_key key, *rest
      else
        by_single_key key
      end
    end

    # Returns true if all arguments are either a valid category or position
    # @param indexes [Array<object>] categories or positions
    # @return [true, false]
    # @example
    #   idx.valid? :a, 2
    #   # => true
    #   idx.valid? 3
    #   # => false
    def valid?(*indexes)
      indexes.all? { |i| to_a.include?(i) || (i.is_a?(Numeric) && i < size) }
    end

    # Returns positions given indexes or positions
    # @note If the arugent is both a valid index and a valid position,
    #   it will treated as valid index
    # @param indexes [Array<object>] indexes or positions
    # @example
    #   x = DaruLite::Index.new [:a, :b, :c]
    #   x.pos :a, 1
    #   # => [0, 1]
    def pos(*indexes)
      indexes = preprocess_range(indexes.first) if indexes.first.is_a? Range

      if indexes.size == 1
        numeric_pos indexes.first
      else
        indexes.map { |index| numeric_pos index }
      end
    end

    def subset(*indexes)
      if indexes.first.is_a? Range
        start = indexes.first.begin
        en = indexes.first.end

        subset_slice start, en
      elsif include? indexes.first
        # Assume 'indexes' contain indexes not positions
        DaruLite::Index.new indexes
      else
        # Assume 'indexes' contain positions not indexes
        DaruLite::Index.new(indexes.map { |k| key k })
      end
    end

    # Takes positional values and returns subset of the self
    #   capturing the indexes at mentioned positions
    # @param positions [Array<Integer>] positional values
    # @return [object] index object
    # @example
    #   idx = DaruLite::Index.new [:a, :b, :c]
    #   idx.at 0, 1
    #   # => #<DaruLite::Index(2): {a, b}>
    def at(*positions)
      positions = preprocess_positions(*positions)
      validate_positions(*positions)
      if positions.is_a? Integer
        key(positions)
      else
        self.class.new(positions.map { |v| key(v) })
      end
    end

    def inspect(threshold = 20)
      name_part = @name ? "#{@name} " : ''
      if size <= threshold
        "#<#{self.class}(#{size}): #{name_part}{#{to_a.join(', ')}}>"
      else
        "#<#{self.class}(#{size}): #{name_part}{#{to_a.first(threshold).join(', ')} ... #{to_a.last}}>"
      end
    end

    def slice(*args)
      start = args[0]
      en = args[1]

      start_idx = @relation_hash[start]
      en_idx    = @relation_hash[en]

      if start_idx.nil?
        nil
      elsif en_idx.nil?
        Array(start_idx..size - 1)
      else
        Array(start_idx..en_idx)
      end
    end

    def subset_slice(*args)
      start = args[0]
      en = args[1]

      if start.is_a?(Integer) && en.is_a?(Integer)
        Index.new @keys[start..en]
      else
        start_idx = @relation_hash[start]
        en_idx    = @relation_hash[en]
        Index.new @keys[start_idx..en_idx]
      end
    end

    # Produce new index from the set union of two indexes.
    def |(other)
      Index.new(to_a | other.to_a)
    end

    # Produce a new index from the set intersection of two indexes
    def &(other)
      Index.new(to_a & other.to_a)
    end

    def to_a
      @keys.dup
    end

    def key(value)
      return nil unless value.is_a?(Numeric)

      @keys[value]
    end

    def include?(index)
      @relation_hash.key? index
    end

    # @note Do not use it to check for Float::NAN as
    #   Float::NAN == Float::NAN is false
    # Return vector of booleans with value at ith position is either
    # true or false depending upon whether index value at position i is equal to
    # any of the values passed in the argument or not
    # @param indexes [Array] values to equate with
    # @return [DaruLite::Vector] vector of boolean values
    # @example
    #   dv = DaruLite::Index.new [1, 2, 3, :one, 'one']
    #   dv.is_values 1, 'one'
    #   # => #<DaruLite::Vector(5)>
    #   #     0  true
    #   #     1  false
    #   #     2  false
    #   #     3  false
    #   #     4  true
    def is_values(*indexes) # rubocop:disable Naming/PredicateName
      bool_array = @keys.map { |r| indexes.include?(r) }
      DaruLite::Vector.new(bool_array)
    end

    def empty?
      @size.zero?
    end

    def dup
      DaruLite::Index.new @keys, name: @name
    end

    def add(*indexes)
      DaruLite::Index.new(to_a + indexes)
    end

    # Takes a positional value and returns a new Index without the element at given position
    # @param position [Integer] positional value
    # @return [object] index object
    # @example
    #   idx = DaruLite::Index.new [:a, :b, :c]
    #   idx.delete_at(0)
    #   # => #<DaruLite::Index(2): {b, c}>
    def delete_at(position)
      indexes = to_a
      indexes.delete_at(position)
      self.class.new(indexes)
    end

    def _dump(*)
      Marshal.dump(relation_hash: @relation_hash)
    end

    def self._load(data)
      h = Marshal.load data

      DaruLite::Index.new(h[:relation_hash].keys)
    end

    # Provide an Index for sub vector produced
    #
    # @option * [Array] the input by user to index the vector
    # @return [Object] the Index object for sub vector produced
    def conform(*)
      self
    end

    def reorder(new_order)
      from = to_a
      self.class.new(new_order.map { |i| from[i] })
    end

    # Sorts a `Index`, according to its values. Defaults to ascending order
    # sorting.
    #
    # @param [Hash] opts the options for sort method.
    # @option opts [Boolean] :ascending False, to get descending order.
    #
    # @return [Index] sorted `Index` according to its values.
    #
    # @example
    #   di = DaruLite::Index.new [100, 99, 101, 1, 2]
    #   # Say you want to sort in descending order
    #   di.sort(ascending: false) #=> DaruLite::Index.new [101, 100, 99, 2, 1]
    #   # Say you want to sort in ascending order
    #   di.sort #=> DaruLite::Index.new [1, 2, 99, 100, 101]
    def sort(opts = {})
      opts = { ascending: true }.merge(opts)

      new_index = @keys.sort
      new_index = new_index.reverse unless opts[:ascending]

      self.class.new(new_index)
    end

    def to_df
      DaruLite::DataFrame.new(name => to_a)
    end

    private

    def guess_index(index)
      case index
      when nil
        []
      when Integer
        index.times.to_a
      when Enumerable
        index.to_a
      else
        raise ArgumentError,
              "Cannot create index from #{index.class} #{index.inspect}"
      end
    end

    def preprocess_range(rng)
      start   = rng.begin
      en      = rng.end

      if start.is_a?(Integer) && en.is_a?(Integer)
        @keys[start..en]
      else
        start_idx = @relation_hash[start]
        en_idx    = @relation_hash[en]

        @keys[start_idx..en_idx]
      end
    end

    def by_range(rng)
      slice rng.begin, rng.end
    end

    def by_multi_key(*key)
      key.map { |k| by_single_key k }
    end

    def by_single_key(key)
      @relation_hash[key] if @relation_hash.key?(key)
    end

    # Raises IndexError when one of the positions is an invalid position
    def validate_positions(*positions)
      positions.each do |pos|
        raise IndexError, "#{pos} is not a valid position." if pos >= size || pos < -size
      end
    end

    # Preprocess ranges, integers and array in appropriate ways
    def preprocess_positions(*positions)
      if positions.size == 1
        case positions.first
        when Integer
          positions.first
        when Range
          size.times.to_a[positions.first]
        else
          raise ArgumentError, 'Unkown position type.'
        end
      else
        positions
      end
    end

    def numeric_pos(key)
      if @relation_hash.key?(key)
        @relation_hash[key]
      elsif key.is_a?(Numeric) && key < size && key >= -size
        key
      else
        raise IndexError, "Specified index #{key.inspect} does not exist"
      end
    end
  end
end
