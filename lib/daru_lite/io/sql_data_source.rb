module DaruLite
  module IO
    class SqlDataSource
      # @private
      class Adapter
        def initialize(conn, query)
          @conn = conn
          @query = query
        end

        def result_hash
          column_names
            .map(&:to_sym)
            .zip(rows.transpose)
            .to_h
        end
      end

      # Private adapter class for connections of ActiveRecord
      # @private
      class ActiveRecordConnectionAdapter < Adapter
        private

        def column_names
          result.columns
        end

        def rows
          result.cast_values
        end

        def result
          @result ||= @conn.exec_query(@query)
        end
      end

      private_constant :ActiveRecordConnectionAdapter

      def self.make_dataframe(db, query)
        new(db, query).make_dataframe
      end

      def initialize(db, query)
        @adapter = init_adapter(db, query)
      end

      def make_dataframe
        DaruLite::DataFrame.new(@adapter.result_hash).tap(&:update)
      end

      private

      def init_adapter(db, query)
        query = String.try_convert(query) or
          raise ArgumentError, "Query must be a string, #{query.class} received"

        db = attempt_sqlite3_connection(db) if db.is_a?(String) && Pathname(db).exist?

        case db
        when ActiveRecord::ConnectionAdapters::AbstractAdapter
          ActiveRecordConnectionAdapter.new(db, query)
        else
          raise ArgumentError, "Unknown database adapter type #{db.class}"
        end
      end

      def attempt_sqlite3_connection(db)
        ActiveRecord::Base.establish_connection(
          adapter: 'sqlite3',
          database: db
        )
        ActiveRecord::Base.connection.tap(&:verify!)
      rescue ActiveRecord::StatementInvalid
        raise ArgumentError, "Expected #{db} to point to a SQLite3 database"
      rescue NameError
        raise NameError, "In order to establish a connection to #{db}, please require 'ActiveRecord'"
      end
    end
  end
end
