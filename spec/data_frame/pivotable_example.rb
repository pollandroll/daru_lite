shared_examples_for 'a pivotable DataFrame' do
  describe "#pivot_table" do
    let(:df) do
      DaruLite::DataFrame.new({
        a: ['foo'  ,  'foo',  'foo',  'foo',  'foo',  'bar',  'bar',  'bar',  'bar'],
        b: ['one'  ,  'one',  'one',  'two',  'two',  'one',  'one',  'two',  'two'],
        c: ['small','large','large','small','small','large','small','large','small'],
        d: [1,2,2,3,3,4,5,6,7],
        e: [2,4,4,6,6,8,10,12,14]
      })
    end

    it "creates row index as per (single) index argument and default aggregates to mean" do
      expect(df.pivot_table(index: [:a])).to eq(DaruLite::DataFrame.new({
        d: [5.5,2.2],
        e: [11.0,4.4]
      }, index: ['bar', 'foo']))
    end

    it "creates row index as per (double) index argument and default aggregates to mean" do
      agg_mi = DaruLite::MultiIndex.from_tuples(
        [
          ['bar', 'large'],
          ['bar', 'small'],
          ['foo', 'large'],
          ['foo', 'small']
        ]
      )
      expect(df.pivot_table(index: [:a, :c]).round(2)).to eq(DaruLite::DataFrame.new({
        d: [5.0 ,  6.0, 2.0, 2.33],
        e: [10.0, 12.0, 4.0, 4.67]
      }, index: agg_mi))
    end

    it "creates row and vector index as per (single) index and (single) vectors args" do
      agg_vectors = DaruLite::MultiIndex.from_tuples([
        [:d, 'one'],
        [:d, 'two'],
        [:e, 'one'],
        [:e, 'two']
      ])
      agg_index = DaruLite::MultiIndex.from_tuples(
        [
          ['bar'],
          ['foo']
        ]
      )

      expect(df.pivot_table(index: [:a], vectors: [:b]).round(2)).to eq(
        DaruLite::DataFrame.new(
          [
            [4.5, 1.67],
            [6.5,  3.0],
            [9.0, 3.33],
            [13,     6]
          ], order: agg_vectors, index: agg_index)
      )
    end

    it "creates row and vector index as per (single) index and (double) vector args" do
      agg_vectors = DaruLite::MultiIndex.from_tuples(
        [
          [:d, 'one', 'large'],
          [:d, 'one', 'small'],
          [:d, 'two', 'large'],
          [:d, 'two', 'small'],
          [:e, 'one', 'large'],
          [:e, 'one', 'small'],
          [:e, 'two', 'large'],
          [:e, 'two', 'small']
        ]
      )

      agg_index = DaruLite::MultiIndex.from_tuples(
        [
          ['bar'],
          ['foo']
        ]
      )

      expect(df.pivot_table(index: [:a], vectors: [:b, :c])).to eq(DaruLite::DataFrame.new(
        [
          [4.0,2.0],
          [5.0,1.0],
          [6.0,nil],
          [7.0,3.0],
          [8.0,4.0],
          [10.0,2.0],
          [12.0,nil],
          [14.0,6.0]
        ], order: agg_vectors, index: agg_index
      ))
    end

    it "creates row and vector index with (double) index and (double) vector args" do
      agg_index = DaruLite::MultiIndex.from_tuples([
        ['bar', 4],
        ['bar', 5],
        ['bar', 6],
        ['bar', 7],
        ['foo', 1],
        ['foo', 2],
        ['foo', 3]
      ])

      agg_vectors = DaruLite::MultiIndex.from_tuples([
        [:e, 'one', 'large'],
        [:e, 'one', 'small'],
        [:e, 'two', 'large'],
        [:e, 'two', 'small']
      ])

      expect(df.pivot_table(index: [:a, :d], vectors: [:b, :c])).to eq(
        DaruLite::DataFrame.new(
          [
            [8  ,nil,nil,nil,nil,  4,nil],
            [nil, 10,nil,nil,  2,nil,nil],
            [nil,nil, 12,nil,nil,nil,nil],
            [nil,nil,nil, 14,nil,nil,  6],
          ], index: agg_index, order: agg_vectors)
      )
    end

    it "only aggregates over the vector specified in the values argument" do
      agg_vectors = DaruLite::MultiIndex.from_tuples(
        [
          [:e, 'one', 'large'],
          [:e, 'one', 'small'],
          [:e, 'two', 'large'],
          [:e, 'two', 'small']
        ]
      )
      agg_index = DaruLite::MultiIndex.from_tuples(
        [
          ['bar'],
          ['foo']
        ]
      )
      expect(df.pivot_table(index: [:a], vectors: [:b, :c], values: :e)).to eq(
        DaruLite::DataFrame.new(
          [
            [8,   4],
            [10,  2],
            [12,nil],
            [14,  6]
          ], order: agg_vectors, index: agg_index
        )
      )

      agg_vectors = DaruLite::MultiIndex.from_tuples(
        [
          [:d, 'one'],
          [:d, 'two'],
          [:e, 'one'],
          [:e, 'two']
        ]
      )
      expect(df.pivot_table(index: [:a], vectors: [:b], values: [:d, :e])).to eq(
        DaruLite::DataFrame.new(
          [
            [4.5,  5.0/3],
            [6.5,    3.0],
            [9.0, 10.0/3],
            [13.0,   6.0]
          ], order: agg_vectors, index: agg_index
        )
      )
    end

    it "overrides default aggregate function to aggregate over sum" do
      agg_vectors = DaruLite::MultiIndex.from_tuples(
        [
          [:e, 'one', 'large'],
          [:e, 'one', 'small'],
          [:e, 'two', 'large'],
          [:e, 'two', 'small']
        ]
      )
      agg_index = DaruLite::MultiIndex.from_tuples(
        [
          ['bar'],
          ['foo']
        ]
      )
      expect(df.pivot_table(index: [:a], vectors: [:b, :c], values: :e, agg: :sum)).to eq(
        DaruLite::DataFrame.new(
          [
            [8,   8],
            [10,  2],
            [12,nil],
            [14, 12]
          ], order: agg_vectors, index: agg_index
        )
      )
    end

    it "raises error if no non-numeric vectors are present" do
      df = DaruLite::DataFrame.new({a: ['a', 'b', 'c'], b: ['b', 'e', 'd']})
      expect {
        df.pivot_table(index: [:a])
      }.to raise_error
    end

    it "raises error if atleast a row index is not specified" do
      expect {
        df.pivot_table
      }.to raise_error
    end

    it "aggregates when nils are present in value vector" do
      df = DaruLite::DataFrame.new({
        a: ['foo'  ,  'foo',  'foo',  'foo',  'foo',  'bar',  'bar',  'bar',  'ice'],
        b: ['one'  ,  'one',  'one',  'two',  'two',  'one',  'one',  'two',  'two'],
        c: ['small','large','large','small','small','large','small','large','small'],
        d: [1,2,2,3,3,4,5,6,7],
        e: [2,nil,4,6,6,8,10,12,nil]
      })

      expect(df.pivot_table index: [:a]).to eq(
        DaruLite::DataFrame.new({
          d:  [5.0, 2.2, 7],
          e:  [10.0, 4.5, nil]
        }, index: DaruLite::Index.new(['bar', 'foo', 'ice'])))
    end

    it "works when nils are present in value vector" do
      df = DaruLite::DataFrame.new({
        a: ['foo'  ,  'foo',  'foo',  'foo',  'foo',  'bar',  'bar',  'bar',  'ice'],
        b: ['one'  ,  'one',  'one',  'two',  'two',  'one',  'one',  'two',  'two'],
        c: ['small','large','large','small','small','large','small','large','small'],
        d: [1,2,2,3,3,4,5,6,7],
        e: [2,nil,4,6,6,8,10,12,nil]
      })

      agg_vectors = DaruLite::MultiIndex.from_tuples(
        [
          [:e, 'one'],
          [:e, 'two']
        ]
      )

      agg_index = DaruLite::MultiIndex.from_tuples(
        [
          ['bar'],
          ['foo'],
          ['ice']
        ]
      )

      expect(df.pivot_table index: [:a], vectors: [:b], values: :e).to eq(
        DaruLite::DataFrame.new(
          [
            [9, 3,  nil],
            [12, 6, nil]
          ], order: agg_vectors, index: agg_index
        )
      )
    end

    it 'performs date pivoting' do
      categories = %i[jan feb mar apr may jun jul aug sep oct nov dec]
      df = DaruLite::DataFrame.rows([
        [2014, 2, 1600.0, 20.0],
        [2014, 3, 1680.0, 21.0],
        [2016, 2, 1600.0, 20.0],
        [2016, 4, 1520.0, 19.0],
      ], order: [:year, :month, :visitors, :days])
      df[:averages] = df[:visitors] / df[:days]
      df[:month] = df[:month].map{|i| categories[i - 1]}
      actual = df.pivot_table(index: :month, vectors: [:year], values: :averages)

      # NB: As you can see, there are some "illogical" parts:
      #     months are sorted lexicographically, then made into multi-index
      #     with one-element-per-tuple, then order of columns is dependent
      #     on which month is lexicographically first (its apr, so, apr-2016
      #     is first row to gather, so 2016 is first column).
      #
      #     All of it is descendance of our group_by implementation (which
      #     always sorts results & always make array keys). I hope that fixing
      #     group_by, even to the extend described at https://github.com/v0dro/daru/issues/152,
      #     will be fix this case also.
      expected =
        DaruLite::DataFrame.new(
          [
            [80.0, 80.0, nil],
            [nil, 80.0, 80.0],
          ], index: DaruLite::MultiIndex.from_tuples([[:apr], [:feb], [:mar]]),
          order: DaruLite::MultiIndex.from_tuples([[:averages, 2016], [:averages, 2014]])
        )
      # Comparing their parts previous to full comparison allows to
      # find complicated differences.
      expect(actual.vectors).to eq expected.vectors
      expect(actual.index).to eq expected.index
      expect(actual).to eq expected
    end
  end
end
