shared_examples_for 'a buildable DataFrame' do
  describe "::rows" do
    let(:rows) do
      [
        [1,2,3,4,5],
        [1,2,3,4,5],
        [1,2,3,4,5],
        [1,2,3,4,5]
      ]
    end

    context DaruLite::Index do
      it "creates a DataFrame from Array rows" do
        df = DaruLite::DataFrame.rows(rows, order: [:a,:b,:c,:d,:e])

        expect(df.index).to eq(DaruLite::Index.new [0,1,2,3])
        expect(df.vectors).to eq(DaruLite::Index.new [:a,:b,:c,:d,:e])
        expect(df[:a]).to eq(DaruLite::Vector.new [1,1,1,1])
      end

      it "creates empty dataframe" do
        df = DaruLite::DataFrame.rows([], order: [:a, :b, :c])

        expect(df.vectors).to eq(DaruLite::Index.new [:a,:b,:c])
        expect(df.index).to be_empty
      end

      it "creates a DataFrame from Vector rows" do
        vector_rows = rows.map { |r| DaruLite::Vector.new r, index: [:a,:b,:c,:d,:e] }

        df = DaruLite::DataFrame.rows(vector_rows, order: [:a,:b,:c,:d,:e])

        expect(df.index)      .to eq(DaruLite::Index.new [0,1,2,3])
        expect(df.vectors)    .to eq(DaruLite::Index.new [:a,:b,:c,:d,:e])
        expect(df[:a]) .to eq(DaruLite::Vector.new [1,1,1,1])
      end

      it 'derives index & order from arrays' do
        df = DaruLite::DataFrame.rows(rows)
        expect(df.index)    .to eq(DaruLite::Index.new [0,1,2,3])
        expect(df.vectors)  .to eq(DaruLite::Index.new %w[0 1 2 3 4])
      end

      it 'derives index & order from vectors' do
        vector_rows = rows.zip(%w[w x y z]).map { |r, n| DaruLite::Vector.new r, index: [:a,:b,:c,:d,:e], name: n }
        df = DaruLite::DataFrame.rows(vector_rows)
        expect(df.index)    .to eq(DaruLite::Index.new %w[w x y z])
        expect(df.vectors)  .to eq(DaruLite::Index.new [:a,:b,:c,:d,:e])
      end

      it 'behaves, when rows are repeated' do
        vector_rows = rows.zip(%w[w w y z]).map { |r, n| DaruLite::Vector.new r, index: [:a,:b,:c,:d,:e], name: n }
        df = DaruLite::DataFrame.rows(vector_rows)
        expect(df.index)    .to eq(DaruLite::Index.new %w[w_1 w_2 y z])
        expect(df.vectors)  .to eq(DaruLite::Index.new [:a,:b,:c,:d,:e])
      end

      it 'behaves, when vectors are unnamed' do
        vector_rows = rows.map { |r| DaruLite::Vector.new r, index: [:a,:b,:c,:d,:e] }
        df = DaruLite::DataFrame.rows(vector_rows)
        expect(df.index)    .to eq(DaruLite::Index.new [0,1,2,3])
        expect(df.vectors)  .to eq(DaruLite::Index.new [:a,:b,:c,:d,:e])
      end
    end

    context DaruLite::MultiIndex do
      it "creates a DataFrame from rows" do
        df = DaruLite::DataFrame.rows(
          rows*3, index: multi_index, order: [:a,:b,:c,:d,:e])

        expect(df.index).to eq(multi_index)
        expect(df.vectors).to eq(DaruLite::Index.new([:a,:b,:c,:d,:e]))
        expect(df[:a]).to eq(DaruLite::Vector.new([1]*12, index: multi_index))
      end

      it "crates a DataFrame from rows (MultiIndex order)" do
        rows = [
          [11, 1, 11, 1],
          [12, 2, 12, 2],
          [13, 3, 13, 3],
          [14, 4, 14, 4]
        ]
        index = DaruLite::MultiIndex.from_tuples([
          [:one,:bar],
          [:one,:baz],
          [:two,:foo],
          [:two,:bar]
        ])

        df = DaruLite::DataFrame.rows(rows, index: index, order: order_mi)
        expect(df.index).to eq(index)
        expect(df.vectors).to eq(order_mi)
        expect(df[:a, :one, :bar]).to eq(DaruLite::Vector.new([11,12,13,14],
          index: index))
      end

      it "creates a DataFrame from Vector rows" do
        rows3 = rows*3
        rows3.map! { |r| DaruLite::Vector.new(r, index: multi_index) }

        df = DaruLite::DataFrame.rows(rows3, order: multi_index)

        expect(df.index).to eq(DaruLite::Index.new(Array.new(rows3.size) { |i| i }))
        expect(df.vectors).to eq(multi_index)
        expect(df[:a,:one,:bar]).to eq(DaruLite::Vector.new([1]*12))
      end
    end
  end
end
