require 'daru_lite/maths/arithmetic/vector'
require 'daru_lite/maths/statistics/vector'
require 'daru_lite/accessors/array_wrapper'
require 'daru_lite/category'
require 'daru_lite/vector/aggregatable'
require 'daru_lite/vector/calculatable'
require 'daru_lite/vector/convertible'
require 'daru_lite/vector/duplicatable'
require 'daru_lite/vector/fetchable'
require 'daru_lite/vector/filterable'
require 'daru_lite/vector/indexable'
require 'daru_lite/vector/iterable'
require 'daru_lite/vector/joinable'
require 'daru_lite/vector/missable'
require 'daru_lite/vector/setable'
require 'daru_lite/vector/sortable'
require 'daru_lite/vector/queryable'

module DaruLite
  class Vector # rubocop:disable Metrics/ClassLength
    include Enumerable
    include DaruLite::Maths::Arithmetic::Vector
    include DaruLite::Maths::Statistics::Vector
    include DaruLite::Vector::Aggregatable
    include DaruLite::Vector::Calculatable
    include DaruLite::Vector::Convertible
    include DaruLite::Vector::Duplicatable
    include DaruLite::Vector::Fetchable
    include DaruLite::Vector::Filterable
    include DaruLite::Vector::Indexable
    include DaruLite::Vector::Iterable
    include DaruLite::Vector::Joinable
    include DaruLite::Vector::Missable
    include DaruLite::Vector::Setable
    include DaruLite::Vector::Sortable
    include DaruLite::Vector::Queryable
    extend Gem::Deprecate

    class << self
      # Create a new vector by specifying the size and an optional value
      # and block to generate values.
      #
      # == Description
      #
      # The *new_with_size* class method lets you create a DaruLite::Vector
      # by specifying the size as the argument. The optional block, if
      # supplied, is run once for populating each element in the Vector.
      #
      # The result of each run of the block is the value that is ultimately
      # assigned to that position in the Vector.
      #
      # == Options
      # :value
      # All the rest like .new
      def new_with_size(n, opts = {}, &block)
        value = opts.delete :value
        block ||= ->(_) { value }
        DaruLite::Vector.new Array.new(n, &block), opts
      end

      # Create a vector using (almost) any object
      # * Array: flattened
      # * Range: transformed using to_a
      # * DaruLite::Vector
      # * Numeric and string values
      #
      # == Description
      #
      # The `Vector.[]` class method creates a vector from almost any
      # object that has a `#to_a` method defined on it. It is similar
      # to R's `c` method.
      #
      # == Usage
      #
      #   a = DaruLite::Vector[1,2,3,4,6..10]
      #   #=>
      #   # <DaruLite::Vector:99448510 @name = nil @size = 9 >
      #   #   nil
      #   # 0   1
      #   # 1   2
      #   # 2   3
      #   # 3   4
      #   # 4   6
      #   # 5   7
      #   # 6   8
      #   # 7   9
      #   # 8  10
      def [](*indexes)
        values = indexes.map do |a|
          a.respond_to?(:to_a) ? a.to_a : a
        end.flatten
        DaruLite::Vector.new(values)
      end

      def _load(data) # :nodoc:
        h = Marshal.load(data)
        DaruLite::Vector.new(h[:data],
                             index: h[:index],
                             name: h[:name],
                             dtype: h[:dtype], missing_values: h[:missing_values])
      end

      def coerce(data, options = {})
        case data
        when DaruLite::Vector
          data
        when Array, Hash
          new(data, options)
        else
          raise ArgumentError, "Can't coerce #{data.class} to #{self}"
        end
      end
    end

    def size
      @data.size
    end

    # The name of the DaruLite::Vector. String.
    attr_reader :name
    # The row index. Can be either DaruLite::Index or DaruLite::MultiIndex.
    attr_reader :index
    # The underlying dtype of the Vector. Can be :array.
    attr_reader :dtype
    attr_reader :nm_dtype
    # An Array or the positions in the vector that are being treated as 'missing'.
    attr_reader :missing_positions

    deprecate :missing_positions, :indexes, 2016, 10
    # Store a hash of labels for values. Supplementary only. Recommend using index
    # for proper usage.
    attr_accessor :labels
    # Store vector data in an array
    attr_reader :data

    # Create a Vector object.
    #
    # == Arguments
    #
    # @param source[Array,Hash] - Supply elements in the form of an Array or a
    # Hash. If Array, a numeric index will be created if not supplied in the
    # options. Specifying more index elements than actual values in *source*
    # will insert *nil* into the surplus index elements. When a Hash is specified,
    # the keys of the Hash are taken as the index elements and the corresponding
    # values as the values that populate the vector.
    #
    # == Options
    #
    # * +:name+  - Name of the vector
    #
    # * +:index+ - Index of the vector
    #
    # * +:dtype+ - The underlying data type. Can be :array.
    # Default :array.
    #
    # * +:missing_values+ - An Array of the values that are to be treated as 'missing'.
    # nil is the default missing value.
    #
    # == Usage
    #
    #   vecarr = DaruLite::Vector.new [1,2,3,4], index: [:a, :e, :i, :o]
    #   vechsh = DaruLite::Vector.new({a: 1, e: 2, i: 3, o: 4})
    def initialize(source, opts = {})
      if opts[:type] == :category
        # Initialize category type vector
        extend DaruLite::Category
        initialize_category source, opts
      else
        # Initialize non-category type vector
        initialize_vector source, opts
      end
    end

    # Two vectors are equal if they have the exact same index values corresponding
    # with the exact same elements. Name is ignored.
    def ==(other)
      case other
      when DaruLite::Vector
        @index == other.index && size == other.size &&
          each_with_index.with_index.all? do |(e, index), position|
            e == other.at(position) && index == other.index.to_a[position]
          end
      else
        super
      end
    end

    # !@method eq
    #   Uses `==` and returns `true` for each **equal** entry
    #   @param [#==, DaruLite::Vector] If scalar object, compares it with each
    #     element in self. If DaruLite::Vector, compares elements with same indexes.
    #   @example (see #where)
    # !@method not_eq
    #   Uses `!=` and returns `true` for each **unequal** entry
    #   @param [#!=, DaruLite::Vector] If scalar object, compares it with each
    #     element in self. If DaruLite::Vector, compares elements with same indexes.
    #   @example (see #where)
    # !@method lt
    #   Uses `<` and returns `true` for each entry **less than** the supplied object
    #   @param [#<, DaruLite::Vector] If scalar object, compares it with each
    #     element in self. If DaruLite::Vector, compares elements with same indexes.
    #   @example (see #where)
    # !@method lteq
    #   Uses `<=` and returns `true` for each entry **less than or equal to** the supplied object
    #   @param [#<=, DaruLite::Vector] If scalar object, compares it with each
    #     element in self. If DaruLite::Vector, compares elements with same indexes.
    #   @example (see #where)
    # !@method mt
    #   Uses `>` and returns `true` for each entry **more than** the supplied object
    #   @param [#>, DaruLite::Vector] If scalar object, compares it with each
    #     element in self. If DaruLite::Vector, compares elements with same indexes.
    #   @example (see #where)
    # !@method mteq
    #   Uses `>=` and returns `true` for each entry **more than or equal to** the supplied object
    #   @param [#>=, DaruLite::Vector] If scalar object, compares it with each
    #     element in self. If DaruLite::Vector, compares elements with same indexes.
    #   @example (see #where)

    # Define the comparator methods with metaprogramming. See documentation
    # written above for functionality of each method. Use these methods with the
    # `where` method to obtain the corresponding Vector/DataFrame.
    {
      eq: :==,
      not_eq: :!=,
      lt: :<,
      lteq: :<=,
      mt: :>,
      mteq: :>=
    }.each do |method, operator|
      define_method(method) do |other|
        mod = DaruLite::Core::Query
        if other.is_a?(DaruLite::Vector)
          mod.apply_vector_operator operator, self, other
        else
          mod.apply_scalar_operator operator, @data, other
        end
      end
      alias_method operator, method if operator != :== && operator != :!=
    end
    alias gt mt
    alias gteq mteq

    # Comparator for checking if any of the elements in *other* exist in self.
    #
    # @param [Array, DaruLite::Vector] other A collection which has elements that
    #   need to be checked for in self.
    # @example Usage of `in`.
    #   vector = DaruLite::Vector.new([1,2,3,4,5])
    #   vector.where(vector.in([3,5]))
    #   #=>
    #   ##<DaruLite::Vector:82215960 @name = nil @size = 2 >
    #   #    nil
    #   #  2   3
    #   #  4   5
    def in(other)
      other = other.zip(Array.new(other.size, 0)).to_h
      DaruLite::Core::Query::BoolArray.new(
        @data.each_with_object([]) do |d, memo|
          memo << (other.key?(d))
        end
      )
    end

    def numeric?
      type == :numeric
    end

    def object?
      type == :object
    end

    # @note Do not use it to check for Float::NAN as
    #   Float::NAN == Float::NAN is false
    # Return vector of booleans with value at ith position is either
    # true or false depending upon whether value at position i is equal to
    # any of the values passed in the argument or not
    # @param values [Array] values to equate with
    # @return [DaruLite::Vector] vector of boolean values
    # @example
    #   dv = DaruLite::Vector.new [1, 2, 3, 2, 1]
    #   dv.is_values 1, 2
    #   # => #<DaruLite::Vector(5)>
    #   #     0  true
    #   #     1  true
    #   #     2 false
    #   #     3  true
    #   #     4  true
    def is_values(*values)
      DaruLite::Vector.new values.map { |v| eq(v) }.inject(:|)
    end

    # Cast a vector to a new data type.
    #
    # == Options
    #
    # * +:dtype+ - :array for Ruby Array..
    def cast(opts = {})
      dt = opts[:dtype]
      raise ArgumentError, "Unsupported dtype #{opts[:dtype]}" unless dt == :array

      @data = cast_vector_to dt unless @dtype == dt
    end

    # Delete an element by value
    def delete(element)
      delete_at index_of(element)
    end

    # Delete element by index
    def delete_at(index)
      @data.delete_at @index[index]
      @index = DaruLite::Index.new(@index.to_a - [index])

      update_position_cache
    end

    # Delete element by position
    def delete_at_position(position)
      @data.delete_at(position)
      @index = @index.delete_at(position)

      update_position_cache
    end

    # The type of data contained in the vector. Can be :object.
    #
    # Running through the data to figure out the kind of data is delayed to the
    # last possible moment.
    def type
      if @type.nil? || @possibly_changed_type
        @type = :numeric
        each do |e|
          next if e.nil? || e.is_a?(Numeric)

          @type = :object
          break
        end
        @possibly_changed_type = false
      end

      @type
    end

    # Tells if vector is categorical or not.
    # @return [true, false] true if vector is of type category, false otherwise
    # @example
    #   dv = DaruLite::Vector.new [1, 2, 3], type: :category
    #   dv.category?
    #   # => true
    def category?
      type == :category
    end

    # Return an Array with the data splitted by a separator.
    #   a=DaruLite::Vector.new(["a,b","c,d","a,b","d"])
    #   a.splitted
    #     =>
    #   [["a","b"],["c","d"],["a","b"],["d"]]
    def splitted(sep = ',')
      @data.map do |s|
        if s.nil?
          nil
        elsif s.respond_to? :split
          s.split sep
        else
          [s]
        end
      end
    end

    # Lags the series by `k` periods.
    #
    # Lags the series by `k` periods, "shifting" data and inserting `nil`s
    # from beginning or end of a vector, while preserving original vector's
    # size.
    #
    # `k` can be positive or negative integer. If `k` is positive, `nil`s
    # are inserted at the beginning of the vector, otherwise they are
    # inserted at the end.
    #
    # @param [Integer] k "shift" the series by `k` periods. `k` can be
    #   positive or negative. (default = 1)
    #
    # @return [DaruLite::Vector] a new vector with "shifted" inital values
    #   and `nil` values inserted. The return vector is the same length
    #   as the orignal vector.
    #
    # @example Lag a vector with different periods `k`
    #
    #   ts = DaruLite::Vector.new(1..5)
    #               # => [1, 2, 3, 4, 5]
    #
    #   ts.lag      # => [nil, 1, 2, 3, 4]
    #   ts.lag(1)   # => [nil, 1, 2, 3, 4]
    #   ts.lag(2)   # => [nil, nil, 1, 2, 3]
    #   ts.lag(-1)  # => [2, 3, 4, 5, nil]
    #
    def lag(k = 1)
      case k
      when 0 then dup
      when 1...size
        copy(([nil] * k) + data.to_a)
      when -size..-1
        copy(data.to_a[k.abs...size])
      else
        copy([])
      end
    end

    # Over rides original inspect for pretty printing in irb
    def inspect(spacing = 20, threshold = 15)
      row_headers = index.is_a?(MultiIndex) ? index.sparse_tuples : index.to_a

      "#<#{self.class}(#{size})#{':category' if category?}>\n" +
        Formatters::Table.format(
          to_a.lazy.zip,
          headers: @name && [@name],
          row_headers: row_headers,
          threshold: threshold,
          spacing: spacing
        )
    end

    # Give the vector a new name
    #
    # @param new_name [Symbol] The new name.
    def rename(new_name)
      @name = new_name
      self
    end

    alias name= rename

    # == Bootstrap
    # Generate +nr+ resamples (with replacement) of size  +s+
    # from vector, computing each estimate from +estimators+
    # over each resample.
    # +estimators+ could be
    # a) Hash with variable names as keys and lambdas as  values
    #   a.bootstrap(:log_s2=>lambda {|v| Math.log(v.variance)},1000)
    # b) Array with names of method to bootstrap
    #   a.bootstrap([:mean, :sd],1000)
    # c) A single method to bootstrap
    #   a.jacknife(:mean, 1000)
    # If s is nil, is set to vector size by default.
    #
    # Returns a DataFrame where each vector is a vector
    # of length +nr+ containing the computed resample estimates.
    def bootstrap(estimators, nr, s = nil)
      s ||= size
      h_est, es, bss = prepare_bootstrap(estimators)

      nr.times do
        bs = sample_with_replacement(s)
        es.each do |estimator|
          bss[estimator].push(h_est[estimator].call(bs))
        end
      end

      es.each do |est|
        bss[est] = DaruLite::Vector.new bss[est]
      end

      DaruLite::DataFrame.new bss
    end

    # == Jacknife
    # Returns a dataset with jacknife delete-+k+ +estimators+
    # +estimators+ could be:
    # a) Hash with variable names as keys and lambdas as values
    #   a.jacknife(:log_s2=>lambda {|v| Math.log(v.variance)})
    # b) Array with method names to jacknife
    #   a.jacknife([:mean, :sd])
    # c) A single method to jacknife
    #   a.jacknife(:mean)
    # +k+ represent the block size for block jacknife. By default
    # is set to 1, for classic delete-one jacknife.
    #
    # Returns a dataset where each vector is an vector
    # of length +cases+/+k+ containing the computed jacknife estimates.
    #
    # == Reference:
    # * Sawyer, S. (2005). Resampling Data: Using a Statistical Jacknife.
    def jackknife(estimators, k = 1) # rubocop:disable Metrics/MethodLength
      raise "n should be divisible by k:#{k}" unless (size % k).zero?

      nb = (size / k).to_i
      h_est, es, ps = prepare_bootstrap(estimators)

      est_n = es.to_h { |v| [v, h_est[v].call(self)] }

      nb.times do |i|
        other = @data.dup
        other.slice!(i * k, k)
        other = DaruLite::Vector.new other

        es.each do |estimator|
          # Add pseudovalue
          ps[estimator].push(
            (nb * est_n[estimator]) - ((nb - 1) * h_est[estimator].call(other))
          )
        end
      end

      es.each do |est|
        ps[est] = DaruLite::Vector.new ps[est]
      end
      DaruLite::DataFrame.new ps
    end

    DATE_REGEXP = /^(\d{2}-\d{2}-\d{4}|\d{4}-\d{2}-\d{2})$/

    # Returns the database type for the vector, according to its content
    def db_type
      # first, detect any character not number
      if @data.any? { |v| v.to_s =~ DATE_REGEXP }
        'DATE'
      elsif @data.any? { |v| v.to_s =~ /[^0-9e.-]/ }
        'VARCHAR (255)'
      elsif @data.any? { |v| v.to_s.include?('.') }
        'DOUBLE'
      else
        'INTEGER'
      end
    end

    # Save the vector to a file
    #
    # == Arguments
    #
    # * filename - Path of file where the vector is to be saved
    def save(filename)
      DaruLite::IO.save self, filename
    end

    def _dump(*) # :nodoc:
      Marshal.dump(
        data: @data.to_a,
        dtype: @dtype,
        name: @name,
        index: @index
      )
    end

    # :nocov:
    def daru_lite_vector(*)
      self
    end
    # :nocov:

    alias dv daru_lite_vector

    # Converts a non category type vector to category type vector.
    # @param [Hash] opts options to convert to category
    # @option opts [true, false] :ordered Specify if vector is ordered or not.
    #   If it is ordered, it can be sorted and min, max like functions would work
    # @option opts [Array] :categories set categories in the specified order
    # @return [DaruLite::Vector] vector with type category
    def to_category(opts = {})
      dv = DaruLite::Vector.new to_a, type: :category, name: @name, index: @index
      dv.ordered = opts[:ordered] || false
      dv.categories = opts[:categories] if opts[:categories]
      dv
    end

    def method_missing(name, *args, &)
      # FIXME: it is shamefully fragile. Should be either made stronger
      # (string/symbol dychotomy, informative errors) or removed totally. - zverok
      if name =~ /(.+)=/
        self[Regexp.last_match(1).to_sym] = args[0]
      elsif has_index?(name)
        self[name]
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      name.to_s.end_with?('=') || has_index?(name) || super
    end

    private

    def copy(values)
      # Make sure values is right-justified to the size of the vector
      values.concat([nil] * (size - values.size)) if values.size < size
      DaruLite::Vector.new(values[0...size], index: @index, name: @name)
    end

    def nil_positions
      @nil_positions ||
        @nil_positions = size.times.select { |i| @data[i].nil? }
    end

    def nan_positions
      @nan_positions ||
        @nan_positions = size.times.select do |i|
          @data[i].respond_to?(:nan?) && @data[i].nan?
        end
    end

    def initialize_vector(source, opts)
      index, source = parse_source(source, opts)
      set_name opts[:name]

      @data  = cast_vector_to(opts[:dtype] || :array, source, opts[:nm_dtype])
      @index = Index.coerce(index || @data.size)

      guard_sizes!

      @possibly_changed_type = true
    end

    def parse_source(source, opts)
      if source.is_a?(Hash)
        [source.keys, source.values]
      else
        [opts[:index], source || []]
      end
    end

    def guard_sizes!
      if @index.size > @data.size
        cast(dtype: :array) # NM with nils seg faults
        @data.fill(nil, @data.size...@index.size)
      elsif @index.size < @data.size
        raise IndexError, "Expected index size >= vector size. Index size : #{@index.size}, vector size : #{@data.size}"
      end
    end

    def guard_type_check(value)
      if (object? && (value.nil? || value.is_a?(Numeric))) || (numeric? && !value.is_a?(Numeric) && !value.nil?)
        @possibly_changed_type = true
      end
    end

    # For an array or hash of estimators methods, returns
    # an array with three elements
    # 1.- A hash with estimators names as keys and lambdas as values
    # 2.- An array with estimators names
    # 3.- A Hash with estimators names as keys and empty arrays as values
    def prepare_bootstrap(estimators)
      h_est = estimators
      h_est = [h_est] unless h_est.is_a?(Array) || h_est.is_a?(Hash)

      if h_est.is_a? Array
        h_est = h_est.to_h do |est|
          [est, ->(v) { DaruLite::Vector.new(v).send(est) }]
        end
      end
      bss = h_est.keys.to_h { |v| [v, []] }

      [h_est, h_est.keys, bss]
    end

    # NOTE: To maintain sanity, this _MUST_ be the _ONLY_ place in daru where the
    # @param dtype [db_type] variable is set and the underlying data type of vector changed.
    def cast_vector_to(dtype, source = nil, _nm_dtype = nil)
      source = @data.to_a if source.nil?

      new_vector =
        case dtype
        when :array   then DaruLite::Accessors::ArrayWrapper.new(source, self)
        when :mdarray then raise NotImplementedError, 'MDArray not yet supported.'
        else raise ArgumentError, "Unknown dtype #{dtype}"
        end

      @dtype = dtype
      new_vector
    end

    def set_name(name) # rubocop:disable Naming/AccessorMethodName
      @name = name.is_a?(Array) ? name.join : name # join in case of MultiIndex tuple
    end

    # Raises IndexError when one of the positions is an invalid position
    def validate_positions(*positions)
      positions.each do |pos|
        raise IndexError, "#{pos} is not a valid position." if pos >= size
      end
    end

    # coerce ranges, integers and array in appropriate ways
    def coerce_positions(*positions)
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

    # Helper method for []=.
    # Assigs existing index to another value
    def modify_vector(indexes, val)
      positions = @index.pos(*indexes)

      if positions.is_a? Numeric
        @data[positions] = val
      else
        positions.each { |pos| @data[pos] = val }
      end
    end

    # Helper method for []=.
    # Add a new index and assign it value
    def insert_vector(indexes, val)
      new_index = @index.add(*indexes)
      # May be create +=
      (new_index.size - @index.size).times { @data << val }
      @index = new_index
    end

    # Works similar to #[]= but also insert the vector in case index is not valid
    # It is there only to be accessed by DaruLite::DataFrame and not meant for user.
    def set(indexes, val)
      cast(dtype: :array) if val.nil? && dtype != :array
      guard_type_check(val)

      if @index.valid?(*indexes)
        modify_vector(indexes, val)
      else
        insert_vector(indexes, val)
      end

      update_position_cache
    end

    def cut_find_category(partitions, val, close_at)
      case close_at
      when :right
        right_index = partitions.index { |i| i > val }
        raise ArgumentError, 'Invalid partition' if right_index.nil?

        left_index = right_index - 1
        "#{partitions[left_index]}-#{partitions[right_index] - 1}"
      when :left
        right_index = partitions.index { |i| i >= val }
        raise ArgumentError, 'Invalid partition' if right_index.nil?

        left_index = right_index - 1
        "#{partitions[left_index] + 1}-#{partitions[right_index]}"
      else
        raise ArgumentError, "Invalid parameter #{close_at} to close_at."
      end
    end

    def cut_categories(partitions, close_at)
      case close_at
      when :right
        Array.new(partitions.size - 1) do |left_index|
          "#{partitions[left_index]}-#{partitions[left_index + 1] - 1}"
        end
      when :left
        Array.new(partitions.size - 1) do |left_index|
          "#{partitions[left_index] + 1}-#{partitions[left_index + 1]}"
        end
      end
    end

    def include_with_nan?(array, value)
      # Returns true if value is included in array.
      # Similar to include? but also works if value is Float::NAN
      if value.respond_to?(:nan?) && value.nan?
        array.any? { |i| i.respond_to?(:nan?) && i.nan? }
      else
        array.include? value
      end
    end

    def update_position_cache
      @nil_positions = nil
      @nan_positions = nil
    end
  end
end
