shared_examples_for 'a missable Vector' do
  describe "#replace_nils" do
    subject { vector.replace_nils(2) }

    let(:vector) { DaruLite::Vector.new([1, 2, 3, nil, nil, 4]) }

    it "replaces all nils with the specified value" do
      expect(subject).to eq(DaruLite::Vector.new([1, 2, 3, 2, 2, 4]))
    end

    it "replaces all nils with the specified value (bang)" do
      vec = DaruLite::Vector.new([1,2,3,nil,nil,4]).replace_nils!(2)
      expect(vec).to eq(DaruLite::Vector.new([1,2,3,2,2,4]))
    end
  end

  describe "#replace_nils" do
    subject { vector.replace_nils!(2) }

    let(:vector) { DaruLite::Vector.new([1, 2, 3, nil, nil, 4]) }

    it "replaces all nils with the specified value (bang)" do
      subject
      expect(vector).to eq(DaruLite::Vector.new([1, 2, 3, 2, 2, 4]))
    end
  end

  describe '#rolling_fillna!' do
    subject do
      DaruLite::Vector.new(
        [Float::NAN, 2, 1, 4, nil, Float::NAN, 3, nil, Float::NAN]
      )
    end

    context 'rolling_fillna! forwards' do
      before { subject.rolling_fillna!(:forward) }

      its(:to_a) { is_expected.to eq [0, 2, 1, 4, 4, 4, 3, 3, 3] }
    end

    context 'rolling_fillna! backwards' do
      before { subject.rolling_fillna!(direction: :backward) }

      its(:to_a) { is_expected.to eq [2, 2, 1, 4, 3, 3, 3, 0, 0] }
    end

    context 'all invalid vector' do
      subject do
        DaruLite::Vector.new(
          [Float::NAN, Float::NAN, Float::NAN, Float::NAN, Float::NAN]
        )
      end

      before { subject.rolling_fillna!(:forward) }

      its(:to_a) { is_expected.to eq [0, 0, 0, 0, 0] }
    end

    context 'with non-default index' do
      subject do
        DaruLite::Vector.new(
          [Float::NAN, 2, 1, 4, nil, Float::NAN, 3, nil, Float::NAN],
          index: %w[a b c d e f g h i]
        )
      end

      before { subject.rolling_fillna!(direction: :backward) }

      it { is_expected.to eq DaruLite::Vector.new([2, 2, 1, 4, 3, 3, 3, 0, 0], index: %w[a b c d e f g h i]) }
    end
  end

  describe '#rolling_fillna' do
    subject do
      DaruLite::Vector.new(
        [Float::NAN, 2, 1, 4, nil, Float::NAN, 3, nil, Float::NAN]
      )
    end

    context 'rolling_fillna forwards' do
      it { expect(subject.rolling_fillna(:forward).to_a).to eq [0, 2, 1, 4, 4, 4, 3, 3, 3] }
    end

    context 'rolling_fillna backwards' do
      it { expect(subject.rolling_fillna(direction: :backward).to_a).to eq [2, 2, 1, 4, 3, 3, 3, 0, 0] }
    end
  end
end
