shared_examples_for 'a queryable DataFrame' do
  describe '#include_values?' do
    let(:df) do
      DaruLite::DataFrame.new({
        a: [1,   2,  3,   4,          Float::NAN, 6, 1],
        b: [:a,  :b, nil, Float::NAN, nil,        3, 5],
        c: ['a', 6,  3,   4,          3,          5, 3],
        d: [1,   2,  3,   5,          1,          2, 5]
      })
    end
    before { df.to_category :b }

    context 'true' do
      it { expect(df.include_values? nil).to eq true }
      it { expect(df.include_values? Float::NAN).to eq true }
      it { expect(df.include_values? nil, Float::NAN).to eq true }
      it { expect(df.include_values? 1, 30).to eq true }
    end

    context 'false' do
      it { expect(df[:a, :c].include_values? nil).to eq false }
      it { expect(df[:c, :d].include_values? Float::NAN).to eq false }
      it { expect(df[:c, :d].include_values? nil, Float::NAN).to eq false }
      it { expect(df.include_values? 10, 20).to eq false }
    end
  end


  describe "#any?" do
    let(:df) do
      DaruLite::DataFrame.new(
        {
          a: [1,2,3,4,5],
          b: [10,20,30,40,50],
          c: [11,22,33,44,55]
        }
      )
    end

    it "returns true if any one of the vectors satisfy condition" do
      expect(df.any? { |v| v[0] == 1 }).to eq(true)
    end

    it "returns false if none of the vectors satisfy the condition" do
      expect(df.any? { |v| v.mean > 100 }).to eq(false)
    end

    it "returns true if any one of the rows satisfy condition" do
      expect(df.any?(:row) { |r| r[:a] == 1 and r[:c] == 11 }).to eq(true)
    end

    it "returns false if none of the rows satisfy the condition" do
      expect(df.any?(:row) { |r| r.mean > 100 }).to eq(false)
    end

    it 'fails on unknown axis' do
      expect { df.any?(:kitten) { |r| r.mean > 100 } }.to raise_error ArgumentError, /axis/
    end
  end

  describe "#all?" do
    let(:df) do
      DaruLite::DataFrame.new(
        {
          a: [1,2,3,4,5],
          b: [10,20,30,40,50],
          c: [11,22,33,44,55]
        }
      )
    end

    it "returns true if all of the vectors satisfy condition" do
      expect(df.all? { |v| v.mean < 40 }).to eq(true)
    end

    it "returns false if any one of the vectors does not satisfy condition" do
      expect(df.all? { |v| v.mean == 30 }).to eq(false)
    end

    it "returns true if all of the rows satisfy condition" do
      expect(df.all?(:row) { |r| r.mean < 70 }).to eq(true)
    end

    it "returns false if any one of the rows does not satisfy condition" do
      expect(df.all?(:row) { |r| r.mean == 30 }).to eq(false)
    end

    it 'fails on unknown axis' do
      expect { df.all?(:kitten) { |r| r.mean > 100 } }.to raise_error ArgumentError, /axis/
    end
  end
end
