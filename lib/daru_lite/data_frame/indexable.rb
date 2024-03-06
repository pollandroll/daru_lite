module DaruLite
  class DataFrame
    module Indexable
      module SetSingleIndexStrategy
        def self.uniq_size(df, col)
          df[col].uniq.size
        end

        def self.new_index(df, col)
          DaruLite::Index.new(df[col].to_a)
        end

        def self.delete_vector(df, col)
          df.delete_vector(col)
        end
      end

      module SetCategoricalIndexStrategy
        def self.new_index(df, col)
          DaruLite::CategoricalIndex.new(df[col].to_a)
        end

        def self.delete_vector(df, col)
          df.delete_vector(col)
        end
      end

      module SetMultiIndexStrategy
        def self.uniq_size(df, cols)
          df[*cols].uniq.size
        end

        def self.new_index(df, cols)
          DaruLite::MultiIndex.from_arrays(df[*cols].map_vectors(&:to_a)).tap do |mi|
            mi.name = cols
          end
        end

        def self.delete_vector(df, cols)
          df.delete_vectors(*cols)
        end
      end

      # Set a particular column as the new DF
      def set_index(new_index_col, keep: false, categorical: false)
        if categorical
          strategy = SetCategoricalIndexStrategy
        elsif new_index_col.respond_to?(:to_a)
          strategy = SetMultiIndexStrategy
          new_index_col = new_index_col.to_a
        else
          strategy = SetSingleIndexStrategy
        end

        unless categorical
          uniq_size = strategy.uniq_size(self, new_index_col)
          raise ArgumentError, 'All elements in new index must be unique.' if @size != uniq_size
        end

        self.index = strategy.new_index(self, new_index_col)
        strategy.delete_vector(self, new_index_col) unless keep
        self
      end

      # Change the index of the DataFrame and preserve the labels of the previous
      # indexing. New index can be DaruLite::Index or any of its subclasses.
      #
      # @param [DaruLite::Index] new_index The new Index for reindexing the DataFrame.
      # @example Reindexing DataFrame
      #   df = DaruLite::DataFrame.new({a: [1,2,3,4], b: [11,22,33,44]},
      #     index: ['a','b','c','d'])
      #   #=>
      #   ##<DaruLite::DataFrame:83278130 @name = b19277b8-c548-41da-ad9a-2ad8c060e273 @size = 4>
      #   #                    a          b
      #   #         a          1         11
      #   #         b          2         22
      #   #         c          3         33
      #   #         d          4         44
      #   df.reindex DaruLite::Index.new(['b', 0, 'a', 'g'])
      #   #=>
      #   ##<DaruLite::DataFrame:83177070 @name = b19277b8-c548-41da-ad9a-2ad8c060e273 @size = 4>
      #   #                    a          b
      #   #         b          2         22
      #   #         0        nil        nil
      #   #         a          1         11
      #   #         g        nil        nil
      def reindex(new_index)
        unless new_index.is_a?(DaruLite::Index)
          raise ArgumentError, 'Must pass the new index of type Index or its ' \
                               "subclasses, not #{new_index.class}"
        end

        cl = DaruLite::DataFrame.new({}, order: @vectors, index: new_index, name: @name)
        new_index.each_with_object(cl) do |idx, memo|
          memo.row[idx] = @index.include?(idx) ? row[idx] : Array.new(ncols)
        end
      end

      def reset_index
        index_df = index.to_df
        names = index.name
        names = [names] unless names.instance_of?(Array)
        new_vectors = names + vectors.to_a
        self.index = index_df.index
        names.each do |name|
          self[name] = index_df[name]
        end
        self.order = new_vectors
        self
      end

      # Reassign index with a new index of type DaruLite::Index or any of its subclasses.
      #
      # @param [DaruLite::Index] idx New index object on which the rows of the dataframe
      #   are to be indexed.
      # @example Reassigining index of a DataFrame
      #   df = DaruLite::DataFrame.new({a: [1,2,3,4], b: [11,22,33,44]})
      #   df.index.to_a #=> [0,1,2,3]
      #
      #   df.index = DaruLite::Index.new(['a','b','c','d'])
      #   df.index.to_a #=> ['a','b','c','d']
      #   df.row['a'].to_a #=> [1,11]
      def index=(idx)
        @index = Index.coerce idx
        @data.each { |vec| vec.index = @index }

        self
      end

      def reindex_vectors(new_vectors)
        unless new_vectors.is_a?(DaruLite::Index)
          raise ArgumentError, 'Must pass the new index of type Index or its ' \
                               "subclasses, not #{new_vectors.class}"
        end

        cl = DaruLite::DataFrame.new({}, order: new_vectors, index: @index, name: @name)
        new_vectors.each_with_object(cl) do |vec, memo|
          memo[vec] = @vectors.include?(vec) ? self[vec] : Array.new(nrows)
        end
      end

      # Reassign vectors with a new index of type DaruLite::Index or any of its subclasses.
      #
      # @param new_index [DaruLite::Index] idx The new index object on which the vectors are to
      #   be indexed. Must of the same size as ncols.
      # @example Reassigning vectors of a DataFrame
      #   df = DaruLite::DataFrame.new({a: [1,2,3,4], b: [:a,:b,:c,:d], c: [11,22,33,44]})
      #   df.vectors.to_a #=> [:a, :b, :c]
      #
      #   df.vectors = DaruLite::Index.new([:foo, :bar, :baz])
      #   df.vectors.to_a #=> [:foo, :bar, :baz]
      def vectors=(new_index)
        raise ArgumentError, 'Can only reindex with Index and its subclasses' unless new_index.is_a?(DaruLite::Index)

        if new_index.size != ncols
          raise ArgumentError, "Specified index length #{new_index.size} not equal to" \
                              "dataframe size #{ncols}"
        end

        @vectors = new_index
        @data.zip(new_index.to_a).each do |vect, name|
          vect.name = name
        end
        self
      end
    end
  end
end
