module DaruLite
  class DataFrame
    module Convertible
      # Create a sql, basen on a given Dataset
      #
      # == Arguments
      #
      # * table - String specifying name of the table that will created in SQL.
      # * charset - Character set. Default is "UTF8".
      #
      # @example
      #
      #  ds = DaruLite::DataFrame.new({
      #   :id   => DaruLite::Vector.new([1,2,3,4,5]),
      #   :name => DaruLite::Vector.new(%w{Alex Peter Susan Mary John})
      #  })
      #  ds.create_sql('names')
      #   #=>"CREATE TABLE names (id INTEGER,\n name VARCHAR (255)) CHARACTER SET=UTF8;"
      #
      def create_sql(table, charset = 'UTF8')
        sql    = "CREATE TABLE #{table} ("
        fields = vectors.to_a.collect do |f|
          v = self[f]
          "#{f} #{v.db_type}"
        end

        sql + fields.join(",\n ") + ") CHARACTER SET=#{charset};"
      end

      # Returns the dataframe.  This can be convenient when the user does not
      # know whether the object is a vector or a dataframe.
      # @return [self] the dataframe
      def to_df
        self
      end

      # Convert all vectors of type *:numeric* into a Matrix.
      def to_matrix
        Matrix.columns each_vector.select(&:numeric?).map(&:to_a)
      end

      # Converts the DataFrame into an array of hashes where key is vector name
      # and value is the corresponding element. The 0th index of the array contains
      # the array of hashes while the 1th index contains the indexes of each row
      # of the dataframe. Each element in the index array corresponds to its row
      # in the array of hashes, which has the same index.
      def to_a
        [each_row.map(&:to_h), @index.to_a]
      end

      # Convert to json. If no_index is false then the index will NOT be included
      # in the JSON thus created.
      def to_json(no_index = true)
        if no_index
          to_a[0].to_json
        else
          to_a.to_json
        end
      end

      # Converts DataFrame to a hash (explicit) with keys as vector names and values as
      # the corresponding vectors.
      def to_h
        @vectors
          .each_with_index
          .map { |vec_name, idx| [vec_name, @data[idx]] }.to_h
      end

      # Convert to html for IRuby.
      def to_html(threshold = DaruLite.max_rows)
        table_thead = to_html_thead
        table_tbody = to_html_tbody(threshold)
        path = if index.is_a?(MultiIndex)
                 File.expand_path('../iruby/templates/dataframe_mi.html.erb', __dir__)
               else
                 File.expand_path('../iruby/templates/dataframe.html.erb', __dir__)
               end
        ERB.new(File.read(path).strip).result(binding)
      end

      def to_html_thead
        table_thead_path =
          if index.is_a?(MultiIndex)
            File.expand_path('../iruby/templates/dataframe_mi_thead.html.erb', __dir__)
          else
            File.expand_path('../iruby/templates/dataframe_thead.html.erb', __dir__)
          end
        ERB.new(File.read(table_thead_path).strip).result(binding)
      end

      def to_html_tbody(threshold = DaruLite.max_rows)
        threshold ||= @size
        table_tbody_path =
          if index.is_a?(MultiIndex)
            File.expand_path('../iruby/templates/dataframe_mi_tbody.html.erb', __dir__)
          else
            File.expand_path('../iruby/templates/dataframe_tbody.html.erb', __dir__)
          end
        ERB.new(File.read(table_tbody_path).strip).result(binding)
      end

      def to_s
        "#<#{self.class}#{": #{@name}" if @name}(#{nrows}x#{ncols})>"
      end
    end
  end
end
