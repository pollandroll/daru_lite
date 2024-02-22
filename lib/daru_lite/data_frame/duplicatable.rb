module DaruLite
  class DataFrame
    module Duplicatable
      extend Gem::Deprecate

      # Duplicate the DataFrame entirely.
      #
      # == Arguments
      #
      # * +vectors_to_dup+ - An Array specifying the names of Vectors to
      # be duplicated. Will duplicate the entire DataFrame if not specified.
      def dup(vectors_to_dup = nil)
        vectors_to_dup ||= @vectors.to_a

        src = vectors_to_dup.map { |vec| @data[@vectors.pos(vec)].dup }
        new_order = DaruLite::Index.new(vectors_to_dup)

        DaruLite::DataFrame.new src, order: new_order, index: @index.dup, name: @name, clone: true
      end

      # Only clone the structure of the DataFrame.
      def clone_structure
        DaruLite::DataFrame.new([], order: @vectors.dup, index: @index.dup, name: @name)
      end

      # Returns a 'view' of the DataFrame, i.e the object ID's of vectors are
      # preserved.
      #
      # == Arguments
      #
      # +vectors_to_clone+ - Names of vectors to clone. Optional. Will return
      # a view of the whole data frame otherwise.
      def clone(*vectors_to_clone)
        vectors_to_clone.flatten! if ArrayHelper.array_of?(vectors_to_clone, Array)
        vectors_to_clone = @vectors.to_a if vectors_to_clone.empty?

        h = vectors_to_clone.map { |vec| [vec, self[vec]] }.to_h
        DaruLite::DataFrame.new(h, clone: false, order: vectors_to_clone, name: @name)
      end

      # Returns a 'shallow' copy of DataFrame if missing data is not present,
      # or a full copy of only valid data if missing data is present.
      def clone_only_valid
        if include_values?(*DaruLite::MISSING_VALUES)
          reject_values(*DaruLite::MISSING_VALUES)
        else
          clone
        end
      end

      # Creates a new duplicate dataframe containing only rows
      # without a single missing value.
      def dup_only_valid(vecs = nil)
        rows_with_nil = @data.map { |vec| vec.indexes(*DaruLite::MISSING_VALUES) }
                             .inject(&:concat)
                             .uniq

        row_indexes = @index.to_a
        (vecs.nil? ? self : dup(vecs)).row[*(row_indexes - rows_with_nil)]
      end
      deprecate :dup_only_valid, :reject_values, 2016, 10
    end
  end
end
