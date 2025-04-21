module DaruLite
  class DataFrame
    module IOAble
      module ClassMethods
        # Load data from a CSV file. Specify an optional block to grab the CSV
        # object and pre-condition it (for example use the `convert` or
        # `header_convert` methods).
        #
        # == Arguments
        #
        # * path - Local path / Remote URL of the file to load specified as a String.
        #
        # == Options
        #
        # Accepts the same options as the DaruLite::DataFrame constructor and CSV.open()
        # and uses those to eventually construct the resulting DataFrame.
        #
        # == Verbose Description
        #
        # You can specify all the options to the `.from_csv` function that you
        # do to the Ruby `CSV.read()` function, since this is what is used internally.
        #
        # For example, if the columns in your CSV file are separated by something
        # other that commas, you can use the `:col_sep` option. If you want to
        # convert numeric values to numbers and not keep them as strings, you can
        # use the `:converters` option and set it to `:numeric`.
        #
        # The `.from_csv` function uses the following defaults for reading CSV files
        # (that are passed into the `CSV.read()` function):
        #
        #   {
        #     :col_sep           => ',',
        #     :converters        => :numeric
        #   }
        def from_csv(path, opts = {}, &)
          DaruLite::IO.from_csv(path, opts, &)
        end

        # Read data from an Excel file into a DataFrame.
        #
        # == Arguments
        #
        # * path - Path of the file to be read.
        #
        # == Options
        #
        # *:worksheet_id - ID of the worksheet that is to be read.
        def from_excel(path, opts = {}, &)
          DaruLite::IO.from_excel(path, opts, &)
        end

        # Read a database query and returns a Dataset
        #
        # @param arh [ActiveRecord::ConnectionAdapters::AbstractAdapter, String] An ActiveRecord connection
        # OR Path to a SQlite3 database.
        # @param query [String] The query to be executed
        #
        # @return A dataframe containing the data resulting from the query
        #
        # USE:
        #
        #  ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: "path/to/sqlite.db")
        #  arh = ActiveRecord::Base.connection
        #  DaruLite::DataFrame.from_sql(dbh, "SELECT * FROM test")
        #
        #  #Alternatively
        #
        #  require 'active_record'
        #  DaruLite::DataFrame.from_sql("path/to/sqlite.db", "SELECT * FROM test")
        def from_sql(arh, query)
          DaruLite::IO.from_sql arh, query
        end

        # Read a dataframe from AR::Relation
        #
        # @param relation [ActiveRecord::Relation] An AR::Relation object from which data is loaded
        # @param fields [Array] Field names to be loaded (optional)
        #
        # @return A dataframe containing the data loaded from the relation
        #
        # USE:
        #
        #   # When Post model is defined as:
        #   class Post < ActiveRecord::Base
        #     scope :active, -> { where.not(published_at: nil) }
        #   end
        #
        #   # You can load active posts into a dataframe by:
        #   DaruLite::DataFrame.from_activerecord(Post.active, :title, :published_at)
        def from_activerecord(relation, *fields)
          DaruLite::IO.from_activerecord relation, *fields
        end

        # Read the database from a plaintext file. For this method to work,
        # the data should be present in a plain text file in columns. See
        # spec/fixtures/bank2.dat for an example.
        #
        # == Arguments
        #
        # * path - Path of the file to be read.
        # * fields - Vector names of the resulting database.
        #
        # == Usage
        #
        #   df = DaruLite::DataFrame.from_plaintext 'spec/fixtures/bank2.dat', [:v1,:v2,:v3,:v4,:v5,:v6]
        def from_plaintext(path, fields)
          DaruLite::IO.from_plaintext path, fields
        end

        def _load(data)
          h = Marshal.load data
          DaruLite::DataFrame.new(
            h[:data],
            index: h[:index],
            order: h[:order],
            name: h[:name]
          )
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end

      # Write this DataFrame to a CSV file.
      #
      # == Arguments
      #
      # * filename - Path of CSV file where the DataFrame is to be saved.
      #
      # == Options
      #
      # * convert_comma - If set to *true*, will convert any commas in any
      # of the data to full stops ('.').
      # All the options accepted by CSV.read() can also be passed into this
      # function.
      def write_csv(filename, opts = {})
        DaruLite::IO.dataframe_write_csv self, filename, opts
      end

      # Write this dataframe to an Excel Spreadsheet
      #
      # == Arguments
      #
      # * filename - The path of the file where the DataFrame should be written.
      def write_excel(filename, opts = {})
        DaruLite::IO.dataframe_write_excel self, filename, opts
      end

      # Insert each case of the Dataset on the selected table
      #
      # == Arguments
      #
      # * arh - ActiveRecord database connection object.
      # * query - Query string.
      #
      # == Usage
      #
      #  ds = DaruLite::DataFrame.new({:id=>DaruLite::Vector.new([1,2,3]), :name=>DaruLite::Vector.new(["a","b","c"])})
      #  ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: "path/to/sqlite.db")
      #  arh = ActiveRecord::Base.connection
      #  ds.write_sql(arh,"test")
      def write_sql(arh, table)
        DaruLite::IO.dataframe_write_sql self, arh, table
      end

      # Use marshalling to save dataframe to a file.
      def save(filename)
        DaruLite::IO.save self, filename
      end

      def _dump(_depth)
        Marshal.dump(
          data: @data,
          index: @index.to_a,
          order: @vectors.to_a,
          name: @name
        )
      end
    end
  end
end
