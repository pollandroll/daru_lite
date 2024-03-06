shared_examples_for 'an iterable DataFrame' do
  describe "#each_index" do
    it "iterates over index" do
      idxs = []
      ret = df.each_index do |index|
        idxs << index
      end

      expect(idxs).to eq([:one, :two, :three, :four, :five])

      expect(ret).to eq(df)
    end
  end

  describe "#each_vector_with_index" do
    it "iterates over vectors with index" do
      idxs = []
      ret = df.each_vector_with_index do |vector, index|
        idxs << index
        expect(vector.index).to eq([:one, :two, :three, :four, :five].to_index)
        expect(vector.class).to eq(DaruLite::Vector)
      end

      expect(idxs).to eq([:a, :b, :c])

      expect(ret).to eq(df)
    end
  end

  describe "#each_row_with_index" do
    it "iterates over rows with indexes" do
      idxs = []
      ret = df.each_row_with_index do |row, idx|
        idxs << idx
        expect(row.index).to eq([:a, :b, :c].to_index)
        expect(row.class).to eq(DaruLite::Vector)
      end

      expect(idxs).to eq([:one, :two, :three, :four, :five])
      expect(ret) .to eq(df)
    end
  end

  describe "#each" do
    it "iterates over rows" do
      ret = df.each(:row) do |row|
        expect(row.index).to eq([:a, :b, :c].to_index)
        expect(row.class).to eq(DaruLite::Vector)
      end

      expect(ret).to eq(df)
    end

    it "iterates over all vectors" do
      ret = df.each do |vector|
        expect(vector.index).to eq([:one, :two, :three, :four, :five].to_index)
        expect(vector.class).to eq(DaruLite::Vector)
      end

      expect(ret).to eq(df)
    end

    it "returns Enumerable if no block specified" do
      ret = df.each
      expect(ret.is_a?(Enumerator)).to eq(true)
    end

    it "raises on unknown axis" do
      expect { df.each(:kitten) }.to raise_error(ArgumentError, /axis/)
    end
  end

  describe "#collect" do
    before do
      @df = DaruLite::DataFrame.new({
        a: [1,2,3,4,5],
        b: [11,22,33,44,55],
        c: [1,2,3,4,5]
      })
    end

    it "collects calculation over rows and returns a Vector from the results" do
      expect(@df.collect(:row) { |row| (row[:a] + row[:c]) * row[:c] }).to eq(
        DaruLite::Vector.new([2,8,18,32,50])
        )
    end

    it "collects calculation over vectors and returns a Vector from the results" do
      expect(@df.collect { |v| v[0] * v[1] + v[4] }).to eq(
        DaruLite::Vector.new([7,297,7], index: [:a, :b, :c])
        )
    end
  end

  describe "#map" do
    it "iterates over rows and returns an Array" do
      ret = df.map(:row) do |row|
        expect(row.class).to eq(DaruLite::Vector)
        row[:a] * row[:c]
      end

      expect(ret).to eq([11, 44, 99, 176, 275])
      expect(df.vectors.to_a).to eq([:a, :b, :c])
    end

    it "iterates over vectors and returns an Array" do
      ret = df.map do |vector|
        vector.mean
      end
      expect(ret).to eq([3.0, 13.0, 33.0])
    end
  end

  describe "#map!" do
    let(:ans_vector) do
      DaruLite::DataFrame.new(
        {
          b: [21,22,23,24,25],
          a: [11,12,13,14,15],
          c: [21,32,43,54,65]
        },
        order: [:a, :b, :c],
        index: [:one, :two, :three, :four, :five]
      )
    end
    let(:ans_row) do
      DaruLite::DataFrame.new(
        {
          b: [12,13,14,15,16],
          a: [2,3,4,5,6],
          c: [12,23,34,45,56]
        },
        order: [:a, :b, :c],
        index: [:one, :two, :three, :four, :five]
      )
    end

    it "destructively maps over the vectors and changes the DF" do
      df.map! do |vector|
        vector + 10
      end
      expect(df).to eq(ans_vector)
    end

    it "destructively maps over the rows and changes the DF" do
      df.map!(:row) do |row|
        row + 1
      end

      expect(df).to eq(ans_row)
    end
  end

  describe "#map_vectors_with_index" do
    it "iterates over vectors with index and returns an Array" do
      idx = []
      ret = df.map_vectors_with_index do |vector, index|
        idx << index
        vector.recode { |e| e += 10}
      end

      expect(ret).to eq([
        DaruLite::Vector.new([11,12,13,14,15],index: [:one, :two, :three, :four, :five]),
        DaruLite::Vector.new([21,22,23,24,25],index: [:one, :two, :three, :four, :five]),
        DaruLite::Vector.new([21,32,43,54,65],index: [:one, :two, :three, :four, :five])])
      expect(idx).to eq([:a, :b, :c])
    end
  end

  # FIXME: collect_VECTORS_with_index, but map_VECTOR_with_index -- ??? -- zverok
  # (Not saying about unfortunate difference between them...)
  describe "#collect_vector_with_index" do
    it "iterates over vectors with index and returns an Array" do
      idx = []
      ret = df.collect_vector_with_index do |vector, index|
        idx << index
        vector.sum
      end

      expect(ret).to eq(DaruLite::Vector.new([15, 65, 165], index: [:a, :b, :c]))
      expect(idx).to eq([:a, :b, :c])
    end
  end

  describe "#map_rows_with_index" do
    it "iterates over rows with index and returns an Array" do
      idx = []
      ret = df.map_rows_with_index do |row, index|
        idx << index
        expect(row.class).to eq(DaruLite::Vector)
        row[:a] * row[:c]
      end

      expect(ret).to eq([11, 44, 99, 176, 275])
      expect(idx).to eq([:one, :two, :three, :four, :five])
    end
  end

  describe '#collect_row_with_index' do
    it "iterates over rows with index and returns a Vector" do
      idx = []
      ret = df.collect_row_with_index do |row, index|
        idx << index
        expect(row.class).to eq(DaruLite::Vector)
        row[:a] * row[:c]
      end

      expected = DaruLite::Vector.new([11, 44, 99, 176, 275], index: df.index)
      expect(ret).to eq(expected)
      expect(idx).to eq([:one, :two, :three, :four, :five])
    end
  end

  describe "#recode" do
    let(:ans_vector) do
      DaruLite::DataFrame.new(
        { b: [21,22,23,24,25],
          a: [11,12,13,14,15],
          c: [21,32,43,54,65]
        },
        order: [:a, :b, :c],
        index: [:one, :two, :three, :four, :five]
      )
    end
    let(:ans_rows) do
      DaruLite::DataFrame.new(
        {
          b: [121, 144, 169, 196, 225],
          a: [1,4,9,16,25],
          c: [121, 484, 1089, 1936, 3025]
        },
        order: [:a, :b, :c],
        index: [:one, :two, :three, :four, :five]
      )
    end
    let(:ans_vector_date_time) do
      DaruLite::DataFrame.new(
        {
          b: [21,22,23,24,25],
          a: [11,12,13,14,15],
          c: [21,32,43,54,65]
        },
        order: [:a, :b, :c],
        index: DaruLite::DateTimeIndex.date_range(start:"2016-02-11", periods:5)
      )
    end
    let(:ans_rows_date_time) do
      DaruLite::DataFrame.new(
        {
          b: [121, 144, 169, 196, 225],
          a: [1,4,9,16,25],
          c: [121, 484, 1089, 1936, 3025]
        },
        order: [:a, :b, :c],
        index: DaruLite::DateTimeIndex.date_range(start:"2016-02-11", periods:5)
      )
    end
    let(:data_frame_date_time) do
      df.dup.tap do |df_dt|
        df_dt.index = DaruLite::DateTimeIndex.date_range(start:"2016-02-11", periods:5)
      end
    end

    it "maps over the vectors of a DataFrame and returns a DataFrame" do
      ret = df.recode do |vector|
        vector.map! { |e| e += 10}
      end

      expect(ret).to eq(ans_vector)
    end

    it "maps over the rows of a DataFrame and returns a DataFrame" do
      ret = df.recode(:row) do |row|
        expect(row.class).to eq(DaruLite::Vector)
        row.map! { |e| e*e }
      end

      expect(ret).to eq(ans_rows)
    end

    it "maps over the vectors of a DataFrame with DateTimeIndex and returns a DataFrame with DateTimeIndex" do
      ret = data_frame_date_time.recode do |vector|
        vector.map! { |e| e += 10}
      end

      expect(ret).to eq(ans_vector_date_time)
    end

    it "maps over the rows of a DataFrame with DateTimeIndex and returns a DataFrame with DateTimeIndex" do
      ret = data_frame_date_time.recode(:row) do |row|
        expect(row.class).to eq(DaruLite::Vector)
        row.map! { |e| e*e }
      end

      expect(ret).to eq(ans_rows_date_time)
    end
  end

  describe '#replace_values' do
    subject do
      DaruLite::DataFrame.new({
        a: [1,    2,          3,   nil,        Float::NAN, nil, 1,   7],
        b: [:a,  :b,          nil, Float::NAN, nil,        3,   5,   8],
        c: ['a',  Float::NAN, 3,   4,          3,          5,   nil, 7]
      })
    end
    before { subject.to_category :b }

    context 'replace nils only' do
      before { subject.replace_values nil, 10 }

      it { is_expected.to be_a DaruLite::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [1, 2, 3, 10, Float::NAN, 10, 1, 7] }
      its(:'b.to_a') { is_expected.to eq [:a,  :b, 10, Float::NAN, 10, 3, 5, 8] }
      its(:'c.to_a') { is_expected.to eq ['a', Float::NAN, 3, 4, 3, 5, 10, 7] }
    end

    context 'replace Float::NAN only' do
      before { subject.replace_values Float::NAN, 10 }

      it { is_expected.to be_a DaruLite::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [1, 2, 3, nil, 10, nil, 1, 7] }
      its(:'b.to_a') { is_expected.to eq [:a,  :b, nil, 10, nil, 3, 5, 8] }
      its(:'c.to_a') { is_expected.to eq ['a', 10, 3, 4, 3, 5, nil, 7] }
    end

    context 'replace both nil and Float::NAN' do
      before { subject.replace_values [nil, Float::NAN], 10 }

      it { is_expected.to be_a DaruLite::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [1, 2, 3, 10, 10, 10, 1, 7] }
      its(:'b.to_a') { is_expected.to eq [:a,  :b, 10, 10, 10, 3, 5, 8] }
      its(:'c.to_a') { is_expected.to eq ['a', 10, 3, 4, 3, 5, 10, 7] }
    end

    context 'replace other values' do
      before { subject.replace_values [1, 5], 10 }

      it { is_expected.to be_a DaruLite::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [10, 2, 3, nil, Float::NAN, nil, 10, 7] }
      its(:'b.to_a') { is_expected.to eq [:a,  :b, nil, Float::NAN, nil, 3, 10, 8] }
      its(:'c.to_a') { is_expected.to eq ['a', Float::NAN, 3, 4, 3, 10, nil, 7] }
    end
  end


  describe "#verify" do
    def create_test(*args, &proc)
      description = args.shift
      fields = args
      [description, fields, proc]
    end

    let(:df) do
      name = DaruLite::Vector.new %w(r1 r2 r3 r4)
      v1   = DaruLite::Vector.new [1, 2, 3, 4]
      v2   = DaruLite::Vector.new [4, 3, 2, 1]
      v3   = DaruLite::Vector.new [10, 20, 30, 40]
      v4   = DaruLite::Vector.new %w(a b a b)

      DaruLite::DataFrame.new({ v1:, v2:, v3:, v4:, id: name }, order: [:v1, :v2, :v3, :v4, :id])
    end

    it "correctly verifies data as per the block" do
      # Correct
      t1 = create_test('If v4=a, v1 odd') do |r|
        r[:v4] == 'b' or (r[:v4] == 'a' and r[:v1].odd?)
      end
      t2 = create_test('v3=v1*10')  { |r| r[:v3] == r[:v1] * 10 }
      # Fail!
      t3 = create_test("v4='b'") { |r| r[:v4] == 'b' }
      exp1 = ["1 [1]: v4='b'", "3 [3]: v4='b'"]
      exp2 = ["1 [r1]: v4='b'", "3 [r3]: v4='b'"]

      dataf = df.verify(t3, t1, t2)
      expect(dataf).to eq(exp1)
    end

    it "uses additional fields to extend error messages" do
      t = create_test("v4='b'", :v2, :v3) { |r| r[:v4] == 'b' }

      dataf = df.verify(:id, t)
      expect(dataf).to eq(["1 [r1]: v4='b' (v2=4, v3=10)", "3 [r3]: v4='b' (v2=2, v3=30)"])
    end
  end

  describe "#merge" do
    it "merges one dataframe with another" do
      a = DaruLite::Vector.new [1, 2, 3]
      b = DaruLite::Vector.new [3, 4, 5]
      c = DaruLite::Vector.new [4, 5, 6]
      d = DaruLite::Vector.new [7, 8, 9]
      e = DaruLite::Vector.new [10, 20, 30]
      ds1 = DaruLite::DataFrame.new({ :a => a, :b => b })
      ds2 = DaruLite::DataFrame.new({ :c => c, :d => d })
      exp = DaruLite::DataFrame.new({ :a => a, :b => b, :c => c, :d => d })

      expect(ds1.merge(ds2)).to eq(exp)
      expect(ds2.merge(ds1)).to eq(
        DaruLite::DataFrame.new({c: c, d: d, a: a, b: b}, order: [:c, :d, :a, :b]))

      ds3 = DaruLite::DataFrame.new({ :a => e })
      exp = DaruLite::DataFrame.new({ :a_1 => a, :a_2 => e, :b => b },
        order: [:a_1, :b, :a_2])

      expect(ds1.merge(ds3)).to eq(exp)
    end

    context "preserves type of vector names" do
      let(:df1) { DaruLite::DataFrame.new({'a'=> [1, 2, 3]}) }
      let(:df2) { DaruLite::DataFrame.new({:b=> [4, 5, 6]}) }
      subject { df1.merge df2 }

      it { is_expected.to be_a DaruLite::DataFrame }
      it { expect(subject['a'].to_a).to eq [1, 2, 3] }
      it { expect(subject[:b].to_a).to eq [4, 5, 6] }
    end

    context "preserves indices for dataframes with same index" do
      let(:index) { ['one','two','three'] }
      let(:df1) { DaruLite::DataFrame.new({ 'a' => [1, 2, 3], 'b' => [3, 4, 5] }, index: index) }
      let(:df2) { DaruLite::DataFrame.new({ 'c' => [4, 5, 6], 'd' => [7, 8, 9] }, index: index) }
      subject { df1.merge df2 }

      its(:index) { is_expected.to eq DaruLite::Index.new(index) }
    end
  end

  describe "#one_to_many" do
    subject { df.one_to_many(['id'], 'car_%v%n') }

    let(:df) do
      DaruLite::DataFrame.rows(
        [
          ['1', 'george', 'red', 10, 'blue', 20, nil, nil],
          ['2', 'fred', 'green', 15, 'orange', 30, 'white', 20],
          ['3', 'alfred', nil, nil, nil, nil, nil, nil]
        ],
        order: [
          'id', 'name', 'car_color1', 'car_value1', 'car_color2',
          'car_value2', 'car_color3', 'car_value3'
        ]
      )
    end
    let(:df_expected) do
      ids     = DaruLite::Vector.new %w(1 1 2 2 2)
      colors  = DaruLite::Vector.new %w(red blue green orange white)
      values  = DaruLite::Vector.new [10, 20, 15, 30, 20]
      col_ids = DaruLite::Vector.new [1, 2, 1, 2, 3]

      DaruLite::DataFrame.new(
        {
          'id' => ids, '_col_id' => col_ids, 'color' => colors, 'value' => values
        },
        order: ['id', '_col_id', 'color', 'value']
      )
    end

    it { is_expected.to eq(df_expected) }
  end
end
