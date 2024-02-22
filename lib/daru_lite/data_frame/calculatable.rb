module DaruLite
  class DataFrame
    module Calculatable
      # Sum all numeric/specified vectors in the DataFrame.
      #
      # Returns a new vector that's a containing a sum of all numeric
      # or specified vectors of the DataFrame. By default, if the vector
      # contains a nil, the sum is nil.
      # With :skipnil argument set to true, nil values are assumed to be
      # 0 (zero) and the sum vector is returned.
      #
      # @param args [Array] List of vectors to sum. Default is nil in which case
      #   all numeric vectors are summed.
      #
      # @option opts [Boolean] :skipnil Consider nils as 0. Default is false.
      #
      # @return Vector with sum of all vectors specified in the argument.
      #   If vecs parameter is empty, sum all numeric vector.
      #
      # @example
      #    df = DaruLite::DataFrame.new({
      #       a: [1, 2, nil],
      #       b: [2, 1, 3],
      #       c: [1, 1, 1]
      #     })
      #    => #<DaruLite::DataFrame(3x3)>
      #           a   b   c
      #       0   1   2   1
      #       1   2   1   1
      #       2 nil   3   1
      #    df.vector_sum [:a, :c]
      #    => #<DaruLite::Vector(3)>
      #       0   2
      #       1   3
      #       2 nil
      #    df.vector_sum
      #    => #<DaruLite::Vector(3)>
      #       0   4
      #       1   4
      #       2 nil
      #    df.vector_sum skipnil: true
      #    => #<DaruLite::Vector(3)>
      #           c
      #       0   4
      #       1   4
      #       2   4
      #
      def vector_sum(*args)
        defaults = { vecs: nil, skipnil: false }
        options = args.last.is_a?(::Hash) ? args.pop : {}
        options = defaults.merge(options)
        vecs = args[0] || options[:vecs]
        skipnil = args[1] || options[:skipnil]

        vecs ||= numeric_vectors
        sum = DaruLite::Vector.new [0] * @size, index: @index, name: @name, dtype: @dtype
        vecs.inject(sum) { |memo, n| self[n].add(memo, skipnil: skipnil) }
      end

      # Calculate mean of the rows of the dataframe.
      #
      # == Arguments
      #
      # * +max_missing+ - The maximum number of elements in the row that can be
      # zero for the mean calculation to happen. Default to 0.
      def vector_mean(max_missing = 0)
        # FIXME: in vector_sum we preserve created vector dtype, but
        # here we are not. Is this by design or ...? - zverok, 2016-05-18
        mean_vec = DaruLite::Vector.new [0] * @size, index: @index, name: "mean_#{@name}"

        each_row_with_index.with_object(mean_vec) do |(row, i), memo|
          memo[i] = row.indexes(*DaruLite::MISSING_VALUES).size > max_missing ? nil : row.mean
        end
      end

      # Returns a vector, based on a string with a calculation based
      # on vector.
      #
      # The calculation will be eval'ed, so you can put any variable
      # or expression valid on ruby.
      #
      # For example:
      #   a = DaruLite::Vector.new [1,2]
      #   b = DaruLite::Vector.new [3,4]
      #   ds = DaruLite::DataFrame.new({:a => a,:b => b})
      #   ds.compute("a+b")
      #   => Vector [4,6]
      def compute(text, &block)
        return instance_eval(&block) if block

        instance_eval(text)
      end

      # DSL for yielding each row and returning a DaruLite::Vector based on the
      # value each run of the block returns.
      #
      # == Usage
      #
      #   a1 = DaruLite::Vector.new([1, 2, 3, 4, 5, 6, 7])
      #   a2 = DaruLite::Vector.new([10, 20, 30, 40, 50, 60, 70])
      #   a3 = DaruLite::Vector.new([100, 200, 300, 400, 500, 600, 700])
      #   ds = DaruLite::DataFrame.new({ :a => a1, :b => a2, :c => a3 })
      #   total = ds.vector_by_calculation { a + b + c }
      #   # <DaruLite::Vector:82314050 @name = nil @size = 7 >
      #   #   nil
      #   # 0 111
      #   # 1 222
      #   # 2 333
      #   # 3 444
      #   # 4 555
      #   # 5 666
      #   # 6 777
      def vector_by_calculation(&block)
        a = each_row.map { |r| r.instance_eval(&block) }

        DaruLite::Vector.new a, index: @index
      end

      def vector_count_characters(vecs = nil)
        vecs ||= @vectors.to_a

        collect_rows do |row|
          vecs.sum { |v| row[v].to_s.size }
        end
      end

      # Generate a summary of this DataFrame based on individual vectors in the DataFrame
      # @return [String] String containing the summary of the DataFrame
      def summary
        summary = "= #{name}"
        summary << "\n  Number of rows: #{nrows}"
        @vectors.each do |v|
          summary << "\n  Element:[#{v}]\n"
          summary << self[v].summary(1)
        end
        summary
      end
    end
  end
end
