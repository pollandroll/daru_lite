shared_examples_for 'an iterable Vector' do |dtype|
  let(:vector) do
    DaruLite::Vector.new(
      [5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, 11, -99, -99],
      dtype:,
      name: :common_all_dtypes
    )
  end

  describe "#collect" do
    subject { vector.collect { |v| v } }

    it "returns an Array" do
      expect(subject).to eq([5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, 11, -99, -99])
    end
  end

  describe "#map" do
    subject { vector.map { |v| v } }

    it "maps" do
      expect(subject).to eq([5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, 11, -99, -99])
    end
  end

  describe "#map!" do
    subject { vector.map! { |v| v + 1 } }

    it "destructively maps" do
      subject
      expect(vector).to eq(
        DaruLite::Vector.new(
          [6, 6, 6, 6, 6, 7, 7, 8, 9, 10, 11, 2, 3, 4, 5, 12, -98, -98],
          dtype:
        )
      )
    end
  end

  describe "#recode" do
    subject { vector.recode { |v| v == -99 ? 1 : 0 } }

    it "maps and returns a vector of dtype of self by default" do
      expect(subject).to eq(
        DaruLite::Vector.new [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1]
      )
      expect(subject.dtype).to eq(:array)
    end
  end

  describe "#recode!" do
    subject { vector.recode! { |v| v == -99 ? 1 : 0 } }

    let(:vector) do
      DaruLite::Vector.new(
        [5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, 11, -99, -99],
        name: :common_all_dtypes,
        dtype:
      )
    end

    it "destructively maps and returns a vector of dtype of self by default" do
      subject
      expect(vector).to eq(
        DaruLite::Vector.new [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1]
      )
      expect(vector.dtype).to eq(dtype)
    end
  end

  describe "#verify" do
    subject { vector.verify { |d| d > 0 } }

    let(:vector) do
      DaruLite::Vector.new([1,2,3,4,5,6,-99,35,-100], dtype:)
    end

    it "returns a hash of invalid data and index of data" do
      expect(subject).to eq({ 6 => -99, 8 => -100 })
    end
  end

  describe '#replace_values' do
    subject do
      DaruLite::Vector.new(
        [1, 2, 1, 4, nil, Float::NAN, nil, Float::NAN],
        index: 11..18
      )
    end

    context 'replace nils and NaNs' do
      before { subject.replace_values [nil, Float::NAN], 10 }

      its(:to_a) { is_expected.to eq [1, 2, 1, 4, 10, 10, 10, 10] }
    end

    context 'replace arbitrary values' do
      before { subject.replace_values [1, 2], 10 }

      its(:to_a) { is_expected.to eq(
        [10, 10, 10, 4, nil, Float::NAN, nil, Float::NAN]) }
    end

    context 'works for single value' do
      before { subject.replace_values nil, 10 }

      its(:to_a) { is_expected.to eq(
        [1, 2, 1, 4, 10, Float::NAN, 10, Float::NAN]) }
    end
  end
end
