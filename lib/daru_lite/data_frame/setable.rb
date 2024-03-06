module DaruLite
  class DataFrame
    module Setable
      # Set rows by positions
      # @param [Array<Integer>] positions positions of rows to set
      # @param [Array, DaruLite::Vector] vector vector to be assigned
      # @example
      #   df = DaruLite::DataFrame.new({
      #     a: [1, 2, 3],
      #     b: ['a', 'b', 'c']
      #   })
      #   df.set_row_at [0, 1], ['x', 'x']
      #   df
      #   #=> #<DaruLite::DataFrame(3x2)>
      #   #       a   b
      #   #   0   x   x
      #   #   1   x   x
      #   #   2   3   c
      def set_row_at(positions, vector)
        validate_positions(*positions, nrows)
        vector =
          if vector.is_a? DaruLite::Vector
            vector.reindex @vectors
          else
            DaruLite::Vector.new vector
          end

        raise SizeError, 'Vector length should match row length' if
          vector.size != @vectors.size

        @data.each_with_index do |vec, pos|
          vec.set_at(positions, vector.at(pos))
        end
        @index = @data[0].index
        set_size
      end

      # Set vectors by positions
      # @param [Array<Integer>] positions positions of vectors to set
      # @param [Array, DaruLite::Vector] vector vector to be assigned
      # @example
      #   df = DaruLite::DataFrame.new({
      #     a: [1, 2, 3],
      #     b: ['a', 'b', 'c']
      #   })
      #   df.set_at [0], ['x', 'y', 'z']
      #   df
      #   #=> #<DaruLite::DataFrame(3x2)>
      #   #       a   b
      #   #   0   x   a
      #   #   1   y   b
      #   #   2   z   c
      def set_at(positions, vector)
        if positions.last == :row
          positions.pop
          return set_row_at(positions, vector)
        end

        validate_positions(*positions, ncols)
        vector =
          if vector.is_a? DaruLite::Vector
            vector.reindex @index
          else
            DaruLite::Vector.new vector
          end

        raise SizeError, 'Vector length should match index length' if
          vector.size != @index.size

        positions.each { |pos| @data[pos] = vector }
      end

      # Insert a new row/vector of the specified name or modify a previous row.
      # Instead of using this method directly, use df.row[:a] = [1,2,3] to set/create
      # a row ':a' to [1,2,3], or df.vector[:vec] = [1,2,3] for vectors.
      #
      # In case a DaruLite::Vector is specified after the equality the sign, the indexes
      # of the vector will be matched against the row/vector indexes of the DataFrame
      # before an insertion is performed. Unmatched indexes will be set to nil.
      def []=(*args)
        vector = args.pop
        axis = extract_axis(args)
        names = args

        dispatch_to_axis axis, :insert_or_modify, names, vector
      end

      def add_row(row, index = nil)
        self.row[*(index || @size)] = row
      end

      def add_vector(n, vector)
        self[n] = vector
      end

      def insert_vector(n, name, source)
        raise ArgumentError unless source.is_a? Array

        vector = DaruLite::Vector.new(source, index: @index, name: @name)
        @data << vector
        @vectors = @vectors.add name
        ordr = @vectors.dup.to_a
        elmnt = ordr.pop
        ordr.insert n, elmnt
        self.order = ordr
      end
    end
  end
end
