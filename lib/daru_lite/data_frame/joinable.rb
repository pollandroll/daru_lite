module DaruLite
  class DataFrame
    module Joinable
      # Concatenate another DataFrame along corresponding columns.
      # If columns do not exist in both dataframes, they are filled with nils
      def concat(other_df)
        vectors = (@vectors.to_a + other_df.vectors.to_a).uniq

        data = vectors.map do |v|
          get_vector_anyways(v).dup.concat(other_df.get_vector_anyways(v))
        end

        DaruLite::DataFrame.new(data, order: vectors)
      end

      # Concatenates another DataFrame as #concat.
      # Additionally it tries to preserve the index. If the indices contain
      # common elements, #union will overwrite the according rows in the
      # first dataframe.
      def union(other_df)
        index = (@index.to_a + other_df.index.to_a).uniq
        df = row[*(@index.to_a - other_df.index.to_a)]

        df = df.concat(other_df)
        df.index = DaruLite::Index.new(index)
        df
      end

      # Merge vectors from two DataFrames. In case of name collision,
      # the vectors names are changed to x_1, x_2 ....
      #
      # @return {DaruLite::DataFrame}
      def merge(other_df)
        unless nrows == other_df.nrows
          raise ArgumentError,
                "Number of rows must be equal in this: #{nrows} and other: #{other_df.nrows}"
        end

        new_fields = (@vectors.to_a + other_df.vectors.to_a)
        new_fields = ArrayHelper.recode_repeated(new_fields)
        DataFrame.new({}, order: new_fields).tap do |df_new|
          (0...nrows).each do |i|
            df_new.add_row row[i].to_a + other_df.row[i].to_a
          end
          df_new.index = @index if @index == other_df.index
          df_new.update
        end
      end

      # Join 2 DataFrames with SQL style joins. Currently supports inner, left
      # outer, right outer and full outer joins.
      #
      # @param [DaruLite::DataFrame] other_df Another DataFrame on which the join is
      #   to be performed.
      # @param [Hash] opts Options Hash
      # @option :how [Symbol] Can be one of :inner, :left, :right or :outer.
      # @option :on [Array] The columns on which the join is to be performed.
      #   Column names specified here must be common to both DataFrames.
      # @option :indicator [Symbol] The name of a vector to add to the resultant
      #   dataframe that indicates whether the record was in the left (:left_only),
      #   right (:right_only), or both (:both) joining dataframes.
      # @return [DaruLite::DataFrame]
      # @example Inner Join
      #   left = DaruLite::DataFrame.new({
      #     :id   => [1,2,3,4],
      #     :name => ['Pirate', 'Monkey', 'Ninja', 'Spaghetti']
      #   })
      #   right = DaruLite::DataFrame.new({
      #     :id => [1,2,3,4],
      #     :name => ['Rutabaga', 'Pirate', 'Darth Vader', 'Ninja']
      #   })
      #   left.join(right, how: :inner, on: [:name])
      #   #=>
      #   ##<DaruLite::DataFrame:82416700 @name = 74c0811b-76c6-4c42-ac93-e6458e82afb0 @size = 2>
      #   #                 id_1       name       id_2
      #   #         0          1     Pirate          2
      #   #         1          3      Ninja          4
      def join(other_df, opts = {})
        DaruLite::Core::Merge.join(self, other_df, opts)
      end

      # Creates a new dataset for one to many relations
      # on a dataset, based on pattern of field names.
      #
      # for example, you have a survey for number of children
      # with this structure:
      #   id, name, child_name_1, child_age_1, child_name_2, child_age_2
      # with
      #   ds.one_to_many([:id], "child_%v_%n"
      # the field of first parameters will be copied verbatim
      # to new dataset, and fields which responds to second
      # pattern will be added one case for each different %n.
      #
      # @example
      #   cases=[
      #     ['1','george','red',10,'blue',20,nil,nil],
      #     ['2','fred','green',15,'orange',30,'white',20],
      #     ['3','alfred',nil,nil,nil,nil,nil,nil]
      #   ]
      #   ds=DaruLite::DataFrame.rows(cases, order:
      #     [:id, :name,
      #      :car_color1, :car_value1,
      #      :car_color2, :car_value2,
      #      :car_color3, :car_value3])
      #   ds.one_to_many([:id],'car_%v%n').to_matrix
      #   #=> Matrix[
      #   #   ["red", "1", 10],
      #   #   ["blue", "1", 20],
      #   #   ["green", "2", 15],
      #   #   ["orange", "2", 30],
      #   #   ["white", "2", 20]
      #   #   ]
      def one_to_many(parent_fields, pattern)
        vars, numbers = one_to_many_components(pattern)

        DataFrame.new([], order: [*parent_fields, '_col_id', *vars]).tap do |ds|
          each_row do |row|
            verbatim = parent_fields.map { |f| [f, row[f]] }.to_h
            numbers.each do |n|
              generated = one_to_many_row row, n, vars, pattern
              next if generated.values.all?(&:nil?)

              ds.add_row(verbatim.merge(generated).merge('_col_id' => n))
            end
          end
          ds.update
        end
      end

      private

      def one_to_many_components(pattern)
        re = Regexp.new pattern.gsub('%v', '(.+?)').gsub('%n', '(\\d+?)')

        vars, numbers =
          @vectors
          .map { |v| v.scan(re) }
          .reject(&:empty?).flatten(1).transpose

        [vars.uniq, numbers.map(&:to_i).sort.uniq]
      end

      def one_to_many_row(row, number, vars, pattern)
        vars
          .to_h do |v|
            name = pattern.sub('%v', v).sub('%n', number.to_s)
            [v, row[name]]
          end
      end
    end
  end
end
