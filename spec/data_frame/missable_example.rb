shared_examples_for 'a missable DataFrame' do
  describe '#rolling_fillna!' do
    subject do
      DaruLite::DataFrame.new({
        a: [1,    2,          3,   nil,        Float::NAN, nil, 1,   7],
        b: [:a,  :b,          nil, Float::NAN, nil,        3,   5,   nil],
        c: ['a',  Float::NAN, 3,   4,          3,          5,   nil, 7]
      })
    end

    context 'rolling_fillna! forwards' do
      before { subject.rolling_fillna!(:forward) }

      it { expect(subject.rolling_fillna!(:forward)).to eq(subject) }
      its(:'a.to_a') { is_expected.to eq [1, 2, 3, 3, 3, 3, 1, 7] }
      its(:'b.to_a') { is_expected.to eq [:a,  :b, :b, :b, :b, 3, 5, 5] }
      its(:'c.to_a') { is_expected.to eq ['a', 'a', 3, 4, 3, 5, 5, 7] }
    end

    context 'rolling_fillna! backwards' do
      before { subject.rolling_fillna!(:backward) }

      it { expect(subject.rolling_fillna!(:backward)).to eq(subject) }
      its(:'a.to_a') { is_expected.to eq [1, 2, 3, 1, 1, 1, 1, 7] }
      its(:'b.to_a') { is_expected.to eq [:a, :b, 3, 3, 3, 3, 5, 0] }
      its(:'c.to_a') { is_expected.to eq ['a', 3, 3, 4, 3, 5, 7, 7] }
    end
  end

  describe "#missing_values_rows" do
    subject { df.missing_values_rows }

    let(:df) do
      a1 = DaruLite::Vector.new [1, nil, 3, 4, 5, nil]
      a2 = DaruLite::Vector.new [10, nil, 20, 20, 20, 30]
      b1 = DaruLite::Vector.new [nil, nil, 1, 1, 1, 2]
      b2 = DaruLite::Vector.new [2, 2, 2, nil, 2, 3]
      c  = DaruLite::Vector.new [nil, 2, 4, 2, 2, 2]

      DaruLite::DataFrame.new({a1:, a2:, b1:, b2:, c: })
    end

    it "returns number of missing values in each row" do
      expect(subject).to eq(DaruLite::Vector.new [2, 3, 0, 1, 0, 1])
    end
  end
end
