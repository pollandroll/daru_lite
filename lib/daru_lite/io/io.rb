module DaruLite
  require_relative 'csv/converters'

  module IOHelpers
    class << self
      def open_local_or_remote_file(path)
        uri = URI.parse(path)
        uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS) ? uri.open : File.open(uri.path)
      end
    end
  end

  module IO
    class << self
      DARU_OPT_KEYS = %i[clone order index name].freeze

      # Functions for loading/writing CSV files
      def from_csv(path, opts = {})
        daru_options, opts = from_csv_prepare_opts opts
        # Preprocess headers for detecting and correcting repetition in
        # case the :headers option is not specified.
        hsh =
          if opts[:headers]
            from_csv_hash_with_headers(path, opts)
          else
            from_csv_hash(path, opts)
              .tap { |hash| daru_options[:order] = hash.keys }
          end
        DaruLite::DataFrame.new(hsh, daru_options)
      end

      def dataframe_write_csv(dataframe, path, opts = {})
        options = {
          converters: :numeric
        }.merge(opts)

        writer = ::CSV.open(path, 'w', **options)
        writer << dataframe.vectors.to_a unless options[:headers] == false

        dataframe.each_row do |row|
          writer << if options[:convert_comma]
                      row.map { |v| v.to_s.tr('.', ',') }
                    else
                      row.to_a
                    end
        end

        writer.close
      end

      private

      def from_csv_prepare_opts(opts)
        opts[:col_sep]           ||= ','
        opts[:skip_blanks]       ||= true
        opts[:converters]        ||= [:numeric]

        opts[:converters] = from_csv_prepare_converters(opts[:converters])

        daru_options = opts.keys.each_with_object({}) do |k, hash|
          hash[k] = opts.delete(k) if DARU_OPT_KEYS.include?(k)
        end
        [daru_options, opts]
      end

      def from_csv_prepare_converters(converters)
        Array(converters).flat_map do |c|
          if ::CSV::Converters[c]
            ::CSV::Converters[c]
          elsif DaruLite::IO::CSV::CONVERTERS[c]
            DaruLite::IO::CSV::CONVERTERS[c]
          else
            c
          end
        end
      end

      def from_csv_hash_with_headers(path, opts)
        opts[:header_converters] ||= :symbol
        ::CSV
          .parse(DaruLite::IOHelpers.open_local_or_remote_file(path), **opts)
          .tap { |c| yield c if block_given? }
          .by_col.to_h { |col_name, values| [col_name, values] }
      end

      def from_csv_hash(path, opts)
        csv_as_arrays =
          ::CSV
          .parse(DaruLite::IOHelpers.open_local_or_remote_file(path), **opts)
          .tap { |c| yield c if block_given? }
          .to_a
        headers       = ArrayHelper.recode_repeated(csv_as_arrays.shift)
        csv_as_arrays = csv_as_arrays.transpose
        headers.each_with_index.to_h { |h, i| [h, csv_as_arrays[i]] }
      end
    end
  end
end
