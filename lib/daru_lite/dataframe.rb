require 'daru_lite/accessors/dataframe_by_row'
require 'daru_lite/data_frame/aggregatable'
require 'daru_lite/data_frame/calculatable'
require 'daru_lite/data_frame/convertible'
require 'daru_lite/data_frame/duplicatable'
require 'daru_lite/data_frame/fetchable'
require 'daru_lite/data_frame/filterable'
require 'daru_lite/data_frame/indexable'
require 'daru_lite/data_frame/i_o_able'
require 'daru_lite/data_frame/iterable'
require 'daru_lite/data_frame/joinable'
require 'daru_lite/data_frame/missable'
require 'daru_lite/data_frame/pivotable'
require 'daru_lite/data_frame/setable'
require 'daru_lite/data_frame/sortable'
require 'daru_lite/data_frame/queryable'
require 'daru_lite/maths/arithmetic/dataframe'
require 'daru_lite/maths/statistics/dataframe'
require 'daru_lite/io/io'

module DaruLite
  class DataFrame # rubocop:disable Metrics/ClassLength
    include DaruLite::DataFrame::Aggregatable
    include DaruLite::DataFrame::Calculatable
    include DaruLite::DataFrame::Convertible
    include DaruLite::DataFrame::Duplicatable
    include DaruLite::DataFrame::Fetchable
    include DaruLite::DataFrame::Filterable
    include DaruLite::DataFrame::Indexable
    include DaruLite::DataFrame::Iterable
    include DaruLite::DataFrame::IOAble
    include DaruLite::DataFrame::Joinable
    include DaruLite::DataFrame::Missable
    include DaruLite::DataFrame::Pivotable
    include DaruLite::DataFrame::Setable
    include DaruLite::DataFrame::Sortable
    include DaruLite::DataFrame::Queryable
    include DaruLite::Maths::Arithmetic::DataFrame
    include DaruLite::Maths::Statistics::DataFrame

    attr_accessor(*Configuration::INSPECT_OPTIONS_KEYS)

    extend Gem::Deprecate

    class << self
      # Create DataFrame by specifying rows as an Array of Arrays or Array of
      # DaruLite::Vector objects.
      def rows(source, opts = {})
        raise SizeError, 'All vectors must have same length' \
          unless source.all? { |v| v.size == source.first.size }

        opts[:order] ||= guess_order(source)

        if ArrayHelper.array_of?(source, Array) || source.empty?
          DataFrame.new(source.transpose, opts)
        elsif ArrayHelper.array_of?(source, Vector)
          from_vector_rows(source, opts)
        else
          raise ArgumentError, "Can't create DataFrame from #{source}"
        end
      end

      # Generates a new dataset, using three vectors
      # - Rows
      # - Columns
      # - Values
      #
      # For example, you have these values
      #
      #   x   y   v
      #   a   a   0
      #   a   b   1
      #   b   a   1
      #   b   b   0
      #
      # You obtain
      #   id  a   b
      #    a  0   1
      #    b  1   0
      #
      # Useful to process outputs from databases
      def crosstab_by_assignation(rows, columns, values)
        raise 'Three vectors should be equal size' if
          rows.size != columns.size || rows.size != values.size

        data = Hash.new do |h, col|
          h[col] = rows.factors.map { |r| [r, nil] }.to_h
        end
        columns.zip(rows, values).each { |c, r, v| data[c][r] = v }

        # FIXME: in fact, WITHOUT this line you'll obtain more "right"
        # data: with vectors having "rows" as an index...
        data = data.transform_values(&:values)
        data[:_id] = rows.factors

        DataFrame.new(data)
      end

      private

      def guess_order(source)
        case source.first
        when Vector # assume that all are Vectors
          source.first.index.to_a
        when Array
          Array.new(source.first.size, &:to_s)
        end
      end

      def from_vector_rows(source, opts)
        index = source.map(&:name)
                      .each_with_index.map { |n, i| n || i }
        index = ArrayHelper.recode_repeated(index)

        DataFrame.new({}, opts).tap do |df|
          source.each_with_index do |row, idx|
            df[index[idx] || idx, :row] = row
          end
        end
      end
    end

    # The vectors (columns) index of the DataFrame
    attr_reader :vectors
    # TOREMOVE
    attr_reader :data

    # The index of the rows of the DataFrame
    attr_reader :index

    # The name of the DataFrame
    attr_reader :name

    # The number of rows present in the DataFrame
    attr_reader :size

    # DataFrame basically consists of an Array of Vector objects.
    # These objects are indexed by row and column by vectors and index Index objects.
    #
    # == Arguments
    #
    # * source - Source from the DataFrame is to be initialized. Can be a Hash
    # of names and vectors (array or DaruLite::Vector), an array of arrays or
    # array of DaruLite::Vectors.
    #
    # == Options
    #
    # +:order+ - An *Array*/*DaruLite::Index*/*DaruLite::MultiIndex* containing the order in
    # which Vectors should appear in the DataFrame.
    #
    # +:index+ - An *Array*/*DaruLite::Index*/*DaruLite::MultiIndex* containing the order
    # in which rows of the DataFrame will be named.
    #
    # +:name+  - A name for the DataFrame.
    #
    # +:clone+ - Specify as *true* or *false*. When set to false, and Vector
    # objects are passed for the source, the Vector objects will not duplicated
    # when creating the DataFrame. Will have no effect if Array is passed in
    # the source, or if the passed DaruLite::Vectors have different indexes.
    # Default to *true*.
    #
    # == Usage
    #
    #   df = DaruLite::DataFrame.new
    #   # =>
    #   # <DaruLite::DataFrame(0x0)>
    #   # Creates an empty DataFrame with no rows or columns.
    #
    #   df = DaruLite::DataFrame.new({}, order: [:a, :b])
    #   #<DaruLite::DataFrame(0x2)>
    #     a   b
    #   # Creates a DataFrame with no rows and columns :a and :b
    #
    #   df = DaruLite::DataFrame.new({a: [1,2,3,4], b: [6,7,8,9]}, order: [:b, :a],
    #     index: [:a, :b, :c, :d], name: :spider_man)
    #
    #   # =>
    #   # <DaruLite::DataFrame:80766980 @name = spider_man @size = 4>
    #   #             b          a
    #   #  a          6          1
    #   #  b          7          2
    #   #  c          8          3
    #   #  d          9          4
    #
    #   df = DaruLite::DataFrame.new([[1,2,3,4],[6,7,8,9]], name: :bat_man)
    #
    #   # =>
    #   # #<DaruLite::DataFrame: bat_man (4x2)>
    #   #             0          1
    #   #  0          1          6
    #   #  1          2          7
    #   #  2          3          8
    #   #  3          4          9
    #
    #   # Dataframe having Index name
    #
    #   df = DaruLite::DataFrame.new({a: [1,2,3,4], b: [6,7,8,9]}, order: [:b, :a],
    #     index: DaruLite::Index.new([:a, :b, :c, :d], name: 'idx_name'),
    #     name: :spider_man)
    #
    #   # =>
    #   # <DaruLite::DataFrame:80766980 @name = spider_man @size = 4>
    #   # idx_name            b          a
    #   #        a          6          1
    #   #        b          7          2
    #   #        c          8          3
    #   #        d          9          4
    #
    #
    #   idx = DaruLite::Index.new [100, 99, 101, 1, 2], name: "s1"
    #   => #<DaruLite::Index(5): s1 {100, 99, 101, 1, 2}>
    #
    #   df = DaruLite::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
    #     c: [11,22,33,44,55]},
    #     order: [:a, :b, :c],
    #     index: idx)
    #    # =>
    #    #<DaruLite::DataFrame(5x3)>
    #    #   s1   a   b   c
    #    #  100   1  11  11
    #    #   99   2  12  22
    #    #  101   3  13  33
    #    #    1   4  14  44
    #    #    2   5  15  55

    def initialize(source = {}, opts = {})
      vectors = opts[:order]
      index = opts[:index] # FIXME: just keyword arges after Ruby 2.1
      @data = []
      @name = opts[:name]

      case source
      when [], {}
        create_empty_vectors(vectors, index)
      when Array
        initialize_from_array source, vectors, index, opts
      when Hash
        initialize_from_hash source, vectors, index, opts
      end

      set_size
      validate
      update
    end

    # Access a row or set/create a row. Refer #[] and #[]= docs for details.
    #
    # == Usage
    #   df.row[:a] # access row named ':a'
    #   df.row[:b] = [1,2,3] # set row ':b' to [1,2,3]
    def row
      DaruLite::Accessors::DataFrameByRow.new(self)
    end

    # Delete a vector
    def delete_vector(vector)
      raise IndexError, "Vector #{vector} does not exist." unless @vectors.include?(vector)

      @data.delete_at @vectors[vector]
      @vectors = DaruLite::Index.new @vectors.to_a - [vector]

      self
    end

    # Deletes a list of vectors
    def delete_vectors(*vectors)
      Array(vectors).each { |vec| delete_vector vec }

      self
    end

    # Delete a row
    def delete_row(index)
      idx = named_index_for index

      raise IndexError, "Index #{index} does not exist." unless @index.include? idx

      @index = DaruLite::Index.new(@index.to_a - [idx])
      each_vector do |vector|
        vector.delete_at idx
      end

      set_size
    end

    # Delete a row based on its position
    # More robust than #delete_row when working with a CategoricalIndex or when the
    # Index includes integers
    def delete_at_position(position)
      raise IndexError, "Position #{position} does not exist." unless position < size

      @index = @index.delete_at(position)
      each_vector { |vector| vector.delete_at_position(position) }

      set_size
    end

    # Creates a DataFrame with the random data, of n size.
    # If n not given, uses original number of rows.
    #
    # @return {DaruLite::DataFrame}
    def bootstrap(n = nil)
      n ||= nrows
      DaruLite::DataFrame.new({}, order: @vectors).tap do |df_boot|
        n.times do
          df_boot.add_row(row[rand(n)])
        end
        df_boot.update
      end
    end

    # Return a nested hash using vector names as keys and an array constructed of
    # hashes with other values. If block provided, is used to provide the
    # values, with parameters +row+ of dataset, +current+ last hash on
    # hierarchy and +name+ of the key to include
    def nest(*tree_keys, &block)
      tree_keys = tree_keys[0] if tree_keys[0].is_a? Array

      each_row.with_object({}) do |row, current|
        # Create tree
        *keys, last = tree_keys
        current = keys.inject(current) { |c, f| c[row[f]] ||= {} }
        name = row[last]

        if block
          current[name] = yield(row, current, name)
        else
          current[name] ||= []
          current[name].push(row.to_h.delete_if { |key, _value| tree_keys.include? key })
        end
      end
    end

    def add_vectors_by_split(name, join = '-', sep = DaruLite::SPLIT_TOKEN)
      self[name]
        .split_by_separator(sep)
        .each { |k, v| self[:"#{name}#{join}#{k}"] = v }
    end

    # Return the number of rows and columns of the DataFrame in an Array.
    def shape
      [nrows, ncols]
    end

    # The number of rows
    def nrows
      @index.size
    end

    # The number of vectors
    def ncols
      @vectors.size
    end

    # Renames the vectors
    #
    # == Arguments
    #
    # * name_map - A hash where the keys are the exising vector names and
    #              the values are the new names.  If a vector is renamed
    #              to a vector name that is already in use, the existing
    #              one is overwritten.
    #
    # == Usage
    #
    #   df = DaruLite::DataFrame.new({ a: [1,2,3,4], b: [:a,:b,:c,:d], c: [11,22,33,44] })
    #   df.rename_vectors :a => :alpha, :c => :gamma
    #   df.vectors.to_a #=> [:alpha, :b, :gamma]
    def rename_vectors(name_map)
      existing_targets = name_map.reject { |k, v| k == v }.values & vectors.to_a
      delete_vectors(*existing_targets)

      new_names = vectors.to_a.map { |v| name_map[v] || v }
      self.vectors = DaruLite::Index.new new_names
    end

    # Renames the vectors and returns itself
    #
    # == Arguments
    #
    # * name_map - A hash where the keys are the exising vector names and
    #              the values are the new names.  If a vector is renamed
    #              to a vector name that is already in use, the existing
    #              one is overwritten.
    #
    # == Usage
    #
    #   df = DaruLite::DataFrame.new({ a: [1,2,3,4], b: [:a,:b,:c,:d], c: [11,22,33,44] })
    #   df.rename_vectors! :a => :alpha, :c => :gamma # df
    def rename_vectors!(name_map)
      rename_vectors(name_map)
      self
    end

    # Converts the vectors to a DaruLite::MultiIndex.
    # The argument passed is used as the MultiIndex's top level
    def add_level_to_vectors(top_level_label)
      tuples = vectors.map { |label| [top_level_label, *label] }
      self.vectors = DaruLite::MultiIndex.from_tuples(tuples)
    end

    def add_vectors_by_split_recode(nm, join = '-', sep = DaruLite::SPLIT_TOKEN)
      self[nm]
        .split_by_separator(sep)
        .each_with_index do |(k, v), i|
          v.rename "#{nm}:#{k}"
          self[:"#{nm}#{join}#{i + 1}"] = v
        end
    end

    # Method for updating the metadata (i.e. missing value positions) of the
    # after assingment/deletion etc. are complete. This is provided so that
    # time is not wasted in creating the metadata for the vector each time
    # assignment/deletion of elements is done. Updating data this way is called
    # lazy loading. To set or unset lazy loading, see the .lazy_update= method.
    def update
      @data.each(&:update) if DaruLite.lazy_update
    end

    # Rename the DataFrame.
    def rename(new_name)
      @name = new_name
      self
    end
    alias name= rename

    # Transpose a DataFrame, tranposing elements and row, column indexing.
    def transpose
      DaruLite::DataFrame.new(
        each_vector.map(&:to_a).transpose,
        index: @vectors,
        order: @index,
        dtype: @dtype,
        name: @name
      )
    end

    # Pretty print in a nice table format for the command line (irb/pry/iruby)
    def inspect(spacing = DaruLite.spacing, threshold = DaruLite.max_rows)
      name_part = @name ? ": #{@name} " : ''
      spacing = [
        headers.to_a.map { |header| header.try(:length) || header.to_s.length }.max,
        spacing
      ].max

      "#<#{self.class}#{name_part}(#{nrows}x#{ncols})>#{$INPUT_RECORD_SEPARATOR}" +
        Formatters::Table.format(
          each_row.lazy,
          row_headers: row_headers,
          headers: headers,
          threshold: threshold,
          spacing: spacing
        )
    end

    def ==(other)
      self.class == other.class   &&
        @size    == other.size    &&
        @index   == other.index   &&
        @vectors == other.vectors &&
        @vectors.to_a.all? { |v| self[v] == other[v] }
    end

    # Converts the specified non category type vectors to category type vectors
    # @param [Array] names of non category type vectors to be converted
    # @return [DaruLite::DataFrame] data frame in which specified vectors have been
    #   converted to category type
    # @example
    #   df = DaruLite::DataFrame.new({
    #     a: [1, 2, 3],
    #     b: ['a', 'a', 'b']
    #   })
    #   df.to_category :b
    #   df[:b].type
    #   # => :category
    def to_category(*names)
      names.each { |n| self[n] = self[n].to_category }
      self
    end

    def method_missing(name, *args, &block)
      if /(.+)=/.match?(name)
        name = name[/(.+)=/].delete('=')
        name = name.to_sym unless has_vector?(name)
        insert_or_modify_vector [name], args[0]
      elsif has_vector?(name)
        self[name]
      elsif has_vector?(name.to_s)
        self[name.to_s]
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      name.to_s.end_with?('=') || has_vector?(name) || super
    end

    def interact_code(vector_names, full)
      dfs = vector_names.zip(full).map do |vec_name, f|
        self[vec_name].contrast_code(full: f).each.to_a
      end

      all_vectors = recursive_product(dfs)
      DaruLite::DataFrame.new all_vectors,
                              order: all_vectors.map(&:name)
    end

    private

    def headers
      DaruLite::Index.new(Array(index.name) + @vectors.to_a)
    end

    def row_headers
      index.is_a?(MultiIndex) ? index.sparse_tuples : index.to_a
    end

    def recursive_product(dfs)
      return dfs.first if dfs.size == 1

      left = dfs.first
      dfs.shift
      right = recursive_product dfs
      left.product(right).map do |dv1, dv2|
        (dv1 * dv2).rename "#{dv1.name}:#{dv2.name}"
      end
    end

    def dispatch_to_axis(axis, method, *args, &block)
      if %i[vector column].include?(axis)
        send(:"#{method}_vector", *args, &block)
      elsif axis == :row
        send(:"#{method}_row", *args, &block)
      else
        raise ArgumentError, "Unknown axis #{axis}"
      end
    end

    def dispatch_to_axis_pl(axis, method, *args, &block)
      if %i[vector column].include?(axis)
        send(:"#{method}_vectors", *args, &block)
      elsif axis == :row
        send(:"#{method}_rows", *args, &block)
      else
        raise ArgumentError, "Unknown axis #{axis}"
      end
    end

    AXES = %i[row vector].freeze

    def extract_axis(names, default = :vector)
      if AXES.include?(names.last)
        names.pop
      else
        default
      end
    end

    def insert_or_modify_vector(name, vector)
      name = name[0] unless @vectors.is_a?(MultiIndex)

      if @index.empty?
        insert_vector_in_empty name, vector
      else
        vec = prepare_for_insert name, vector

        assign_or_add_vector name, vec
      end
    end

    def assign_or_add_vector(name, v)
      # FIXME: fix this jugaad. need to make changes in Indexing itself.
      begin
        pos = @vectors[name]
      rescue IndexError
        pos = name
      end

      if pos.is_a?(DaruLite::Index)
        assign_multiple_vectors pos, v
      elsif pos == name &&
            (@vectors.include?(name) || (pos.is_a?(Integer) && pos < @data.size))

        @data[pos] = v
      else
        assign_or_add_vector_rough name, v
      end
    end

    def assign_multiple_vectors(pos, v)
      pos.each do |p|
        @data[@vectors[p]] = v
      end
    end

    def assign_or_add_vector_rough(name, v)
      @vectors |= [name] unless @vectors.include?(name)
      @data[@vectors[name]] = v
    end

    def insert_vector_in_empty(name, vector)
      vec = Vector.coerce(vector.to_a, name: coerce_name(name))

      @index = vec.index
      assign_or_add_vector name, vec
      set_size

      @data.map! { |v| v.empty? ? v.reindex(@index) : v }
    end

    def prepare_for_insert(name, arg)
      if arg.is_a? DaruLite::Vector
        prepare_vector_for_insert name, arg
      elsif arg.respond_to?(:to_a)
        prepare_enum_for_insert name, arg
      else
        prepare_value_for_insert name, arg
      end
    end

    def prepare_vector_for_insert(name, vector)
      # so that index-by-index assignment is avoided when possible.
      return vector.dup if vector.index == @index

      DaruLite::Vector.new([], name: coerce_name(name), index: @index).tap do |v|
        @index.each do |idx|
          v[idx] = vector.index.include?(idx) ? vector[idx] : nil
        end
      end
    end

    def prepare_enum_for_insert(name, enum)
      if @size != enum.size
        raise "Specified vector of length #{enum.size} cannot be inserted in DataFrame of size #{@size}"
      end

      DaruLite::Vector.new(enum, name: coerce_name(name), index: @index)
    end

    def prepare_value_for_insert(name, value)
      DaruLite::Vector.new(Array(value) * @size, name: coerce_name(name), index: @index)
    end

    def insert_or_modify_row(indexes, vector)
      vector = coerce_vector vector

      raise SizeError, 'Vector length should match row length' if
        vector.size != @vectors.size

      @data.each_with_index do |vec, pos|
        vec.send(:set, indexes, vector.at(pos))
      end
      @index = @data[0].index

      set_size
    end

    def create_empty_vectors(vectors, index)
      @vectors = Index.coerce vectors
      @index   = Index.coerce index

      @data = @vectors.map do |name|
        DaruLite::Vector.new([], name: coerce_name(name), index: @index)
      end
    end

    def validate_labels
      if @vectors && @vectors.size != @data.size
        raise IndexError, "Expected equal number of vector names (#{@vectors.size}) " \
                          "for number of vectors (#{@data.size})."
      end

      return unless @index && @data[0] && @index.size != @data[0].size

      raise IndexError, 'Expected number of indexes same as number of rows'
    end

    def validate_vector_sizes
      @data.each do |vector|
        raise IndexError, 'Expected vectors with equal length' if vector.size != @size
      end
    end

    def validate
      validate_labels
      validate_vector_sizes
    end

    def set_size
      @size = @index.size
    end

    def named_index_for(index)
      if @index.include? index
        index
      elsif @index.key index
        @index.key index
      else
        raise IndexError, "Specified index #{index} does not exist."
      end
    end

    def create_vectors_index_with(vectors, source)
      vectors = source.keys if vectors.nil?

      @vectors =
        if vectors.is_a?(Index) || vectors.is_a?(MultiIndex)
          vectors
        else
          DaruLite::Index.new((vectors + (source.keys - vectors)).uniq)
        end
    end

    def all_vectors_have_equal_indexes?(source)
      idx = source.values[0].index

      source.values.all? { |vector| idx == vector.index }
    end

    def coerce_name(potential_name)
      potential_name.is_a?(Array) ? potential_name.join : potential_name
    end

    def initialize_from_array(source, vectors, index, opts)
      raise ArgumentError, 'All objects in data source should be same class' \
        unless source.map(&:class).uniq.size == 1

      case source.first
      when Array
        vectors ||= (0..source.size - 1).to_a
        initialize_from_array_of_arrays source, vectors, index, opts
      when Vector
        vectors ||= (0..source.size - 1).to_a
        initialize_from_array_of_vectors source, vectors, index, opts
      when Hash
        initialize_from_array_of_hashes source, vectors, index, opts
      else
        raise ArgumentError, "Can't create DataFrame from #{source}"
      end
    end

    def initialize_from_array_of_arrays(source, vectors, index, _opts)
      if source.size != vectors.size
        raise ArgumentError, "Number of vectors (#{vectors.size}) should " \
                             "equal order size (#{source.size})"
      end

      @index   = Index.coerce(index || source[0].size)
      @vectors = Index.coerce(vectors)

      update_data source, vectors
    end

    def initialize_from_array_of_vectors(source, vectors, index, opts)
      clone = opts[:clone] != false
      hsh = vectors.each_with_index.to_h do |name, idx|
        [name, source[idx]]
      end
      initialize(hsh, index: index, order: vectors, name: @name, clone: clone)
    end

    def initialize_from_array_of_hashes(source, vectors, index, _opts)
      names =
        if vectors.nil?
          source[0].keys
        else
          (vectors + source[0].keys).uniq
        end
      @vectors = DaruLite::Index.new(names)
      @index = DaruLite::Index.new(index || source.size)

      @data = @vectors.map do |name|
        v = source.map { |h| h.fetch(name) { h[name.to_s] } }
        DaruLite::Vector.new(v, name: coerce_name(name), index: @index)
      end
    end

    def initialize_from_hash(source, vectors, index, opts)
      create_vectors_index_with vectors, source

      if ArrayHelper.array_of?(source.values, Vector)
        initialize_from_hash_with_vectors source, index, opts
      else
        initialize_from_hash_with_arrays source, index, opts
      end
    end

    def initialize_from_hash_with_vectors(source, index, opts)
      vectors_have_same_index = all_vectors_have_equal_indexes?(source)

      clone = opts[:clone] != false
      clone = true unless index || vectors_have_same_index

      @index = deduce_index index, source, vectors_have_same_index

      if clone
        @data = clone_vectors source, vectors_have_same_index
      else
        @data.concat source.values
      end
    end

    def deduce_index(index, source, vectors_have_same_index)
      if !index.nil?
        Index.coerce index
      elsif vectors_have_same_index
        source.values[0].index.dup
      else
        all_indexes = source
                      .values.map { |v| v.index.to_a }
                      .flatten.uniq.sort # sort only if missing indexes detected

        DaruLite::Index.new all_indexes
      end
    end

    def clone_vectors(source, vectors_have_same_index)
      @vectors.map do |vector|
        # avoids matching indexes of vectors if all the supplied vectors
        # have the same index.
        if vectors_have_same_index
          source[vector].dup
        else
          DaruLite::Vector.new([], name: vector, index: @index).tap do |v|
            @index.each do |idx|
              v[idx] = source[vector].index.include?(idx) ? source[vector][idx] : nil
            end
          end
        end
      end
    end

    def initialize_from_hash_with_arrays(source, index, _opts)
      @index = Index.coerce(index || source.values[0].size)

      @vectors.each do |name|
        @data << DaruLite::Vector.new(source[name].dup, name: coerce_name(name), index: @index)
      end
    end

    # Raises IndexError when one of the positions is not a valid position
    def validate_positions(*positions, size)
      positions.each do |pos|
        raise IndexError, "#{pos} is not a valid position." if pos >= size
      end
    end

    # Accepts hash, enumerable and vector and align it properly so it can be added
    def coerce_vector(vector)
      case vector
      when DaruLite::Vector
        vector.reindex @vectors
      when Hash
        DaruLite::Vector.new(vector).reindex @vectors
      else
        DaruLite::Vector.new vector
      end
    end

    def update_data(source, vectors)
      @data = @vectors.each_with_index.map do |_vec, idx|
        DaruLite::Vector.new(source[idx], index: @index, name: vectors[idx])
      end
    end
  end
end
