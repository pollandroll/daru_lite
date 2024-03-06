shared_examples_for 'an indexable DataFrame' do
  describe "#set_index" do
    let(:df) do
      DaruLite::DataFrame.new(
        {
          a: [1,2,3,4,5],
          b: ['a','b','c','d','e'],
          c: [11,22,33,44,55]
        }
      )
    end

    it "sets a particular column as the index and deletes that column" do
      df.set_index(:b)
      expect(df).to eq(
        DaruLite::DataFrame.new({
          a: [1,2,3,4,5],
          c: [11,22,33,44,55]
          }, index: ['a','b','c','d','e'])
        )
    end

    it "sets a particular column as index but keeps that column" do
      expect(df.set_index(:c, keep: true)).to eq(
        DaruLite::DataFrame.new({
          a: [1,2,3,4,5],
          b: ['a','b','c','d','e'],
          c: [11,22,33,44,55]
          }, index: [11,22,33,44,55]))
      expect(df[:c]).to eq(df[:c])
    end

    it "sets categorical index if categorical is true" do
      data = {
        a: [1, 2, 3, 4, 5],
        b: [:a, 1, :a, 1, 'c'],
        c: %w[a b c d e]
      }
      df = DaruLite::DataFrame.new(data)
      df.set_index(:b, categorical: true)
      expected = DaruLite::DataFrame.new(
        data.slice(:a, :c),
        index: DaruLite::CategoricalIndex.new(data[:b])
      )
      expect(df).to eq(expected)
    end

    it "raises error if all elements in the column aren't unique" do
      jholu = DaruLite::DataFrame.new({
        a: ['a','b','a'],
        b: [1,2,4]
        })

      expect {
        jholu.set_index(:a)
      }.to raise_error(ArgumentError)
    end

    it "sets multiindex if array is given" do
      df = DaruLite::DataFrame.new({
        a: %w[a a b b],
        b: [1, 2, 1, 2],
        c: %w[a b c d]
      })
      df.set_index(%i[a b])
      expected =
        DaruLite::DataFrame.new(
          { c: %w[a b c d] },
          index: DaruLite::MultiIndex.from_tuples(
            [['a', 1], ['a', 2], ['b', 1], ['b', 2]]
          )
        ).tap do |df|
          df.index.name = %i[a b]
          df
        end
      expect(df).to eq(expected)
    end
  end

  describe "#reindex" do
    subject { df.reindex(DaruLite::Index.new([1,3,0,8,2])) }

    let(:df) do
      DaruLite::DataFrame.new({
        a: [1,2,3,4,5],
        b: [11,22,33,44,55],
        c: %w(a b c d e)
      })
    end

    it "re indexes and aligns accordingly" do
      expect(subject).to eq(
        DaruLite::DataFrame.new(
          {
            a: [2,4,1,nil,3],
            b: [22,44,11,nil,33],
            c: ['b','d','a',nil,'c']
          },
          index: DaruLite::Index.new([1,3,0,8,2])
        )
      )
    end

    it { is_expected.to_not eq(df) }
  end

  describe '#reset_index' do
    context 'when Index' do
      subject do
        DaruLite::DataFrame.new(
          {'vals' => [1,2,3,4,5]},
          index: DaruLite::Index.new(%w[a b c d e], name: 'indices')
        ).reset_index
      end

      it { is_expected.to eq DaruLite::DataFrame.new(
        'indices' => %w[a b c d e],
        'vals' => [1,2,3,4,5]
      )}
    end

    context 'when MultiIndex' do
      subject do
        mi = DaruLite::MultiIndex.from_tuples([
          [0, 'a'], [0, 'b'], [1, 'a'], [1, 'b']
        ])
        mi.name = %w[nums alphas]
        DaruLite::DataFrame.new(
          {'vals' => [1,2,3,4]},
          index: mi
        ).reset_index
      end

      it { is_expected.to eq DaruLite::DataFrame.new(
        'nums' => [0,0,1,1],
        'alphas' => %w[a b a b],
        'vals' => [1,2,3,4]
      )}
    end
  end

  describe "#index=" do
    let(:df) do
      DaruLite::DataFrame.new({
        a: [1,2,3,4,5],
        b: [11,22,33,44,55],
        c: %w(a b c d e)
      })
    end

    it "simply reassigns the index" do
      df.index = DaruLite::Index.new(['4','foo', :bar, 0, 23])
      expect(df.row['foo']).to eq(DaruLite::Vector.new([2,22,'b'], index: [:a,:b,:c]))
    end

    it "raises error for improper length index" do
      expect {
        df.index = DaruLite::Index.new([1,2])
      }.to raise_error(ArgumentError)
    end

    it "is able to accept array" do
      df.index = (1..5).to_a
      expect(df.index).to eq DaruLite::Index.new (1..5).to_a
    end
  end

  describe "#reindex_vectors" do
    it "re indexes vectors and aligns accordingly" do
      df = DaruLite::DataFrame.new({
        a: [1,2,3,4,5],
        b: [11,22,33,44,55],
        c: %w(a b c d e)
      })

      ans = df.reindex_vectors(DaruLite::Index.new([:b, 'a', :a]))
      expect(ans).to eq(DaruLite::DataFrame.new({
        :b  => [11,22,33,44,55],
        'a' => [nil, nil, nil, nil, nil],
        :a  => [1,2,3,4,5]
      }, order: [:b, 'a', :a]))
    end

    it 'raises ArgumentError if argument was not an index' do
      df = DaruLite::DataFrame.new([])
      expect { df.reindex_vectors([]) }.to raise_error(ArgumentError)
    end
  end

  describe "#vectors=" do
    let(:df) do
      DaruLite::DataFrame.new({
        a: [1,2,3,4,5],
        b: [11,22,33,44,55],
        c: %w(a b c d e)
      })
    end

    it "simply reassigns vectors" do
      df.vectors = DaruLite::Index.new(['b',0,'m'])

      expect(df.vectors).to eq(DaruLite::Index.new(['b',0,'m']))
      expect(df['b']).to eq(DaruLite::Vector.new([1,2,3,4,5]))
      expect(df[0]).to eq(DaruLite::Vector.new([11,22,33,44,55]))
      expect(df['m']).to eq(DaruLite::Vector.new(%w(a b c d e)))
    end

    it "raises error for improper length index" do
      expect {
        df.vectors = DaruLite::Index.new([1,2,'3',4,'5'])
      }.to raise_error(ArgumentError)
    end

    it "change name of vectors in @data" do
      new_index_array = [:k, :l, :m]
      df.vectors = DaruLite::Index.new(new_index_array)

      expect(df.data.map { |vector| vector.name }).to eq(new_index_array)
    end
  end
end
