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
