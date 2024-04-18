shared_examples_for 'a filterable Vector' do |dtype|
  let(:vector) do
    DaruLite::Vector.new([1, 22, 33, 45, 65, 32, 524, 656, 123, 99, 77], dtype:)
  end

  describe "#delete_if" do
    subject { vector.delete_if { |d| d % 11 == 0 } }

    it "deletes elements if block evaluates to true" do
      expect(subject).to eq(
        DaruLite::Vector.new(
          [1, 45, 65, 32, 524, 656, 123],
          index: [0, 3, 4, 5, 6, 7, 8],
          dtype:
        )
      )
    end

    it 'does not change dtype' do
      expect(subject.dtype).to eq(dtype)
    end
  end

  describe "#keep_if" do
    subject { vector.keep_if { |d| d < 35 } }

    it "keeps elements if block returns true" do
      expect(subject).to eq(
        DaruLite::Vector.new(
          [1, 22, 33, 32],
          index: [0, 1, 2, 5],
          dtype:
        )
      )
    end

    it 'does not change dtype' do
      expect(subject.dtype).to eq(dtype)
    end
  end

  describe "#uniq" do
    subject { vector.uniq }

    let(:vector) do
      DaruLite::Vector.new([1, 2, 2, 2.0, 3, 3.0], index:[:a, :b, :c, :d, :e, :f])
    end

    it "keeps only unique values" do
      expect(subject).to eq(DaruLite::Vector.new [1, 2, 2.0, 3, 3.0], index: [:a, :b, :d, :e, :f])
    end
  end

  describe '#reject_values'do
    let(:vector) do
      DaruLite::Vector.new(
        [1, nil, 3, :a, Float::NAN, nil, Float::NAN, 1],
        index: 11..18
      )
    end

    context 'reject only nils' do
      subject { vector.reject_values nil }

      it { is_expected.to be_a DaruLite::Vector }
      its(:to_a) { is_expected.to eq [1, 3, :a, Float::NAN, Float::NAN, 1] }
      its(:'index.to_a') { is_expected.to eq [11, 13, 14, 15, 17, 18] }
    end

    context 'reject only float::NAN' do
      subject { vector.reject_values Float::NAN }

      it { is_expected.to be_a DaruLite::Vector }
      its(:to_a) { is_expected.to eq [1, nil, 3, :a, nil, 1] }
      its(:'index.to_a') { is_expected.to eq [11, 12, 13, 14, 16, 18] }
    end

    context 'reject both nil and float::NAN' do
      subject { vector.reject_values nil, Float::NAN }

      it { is_expected.to be_a DaruLite::Vector }
      its(:to_a) { is_expected.to eq [1, 3, :a, 1] }
      its(:'index.to_a') { is_expected.to eq [11, 13, 14, 18] }
    end

    context 'reject any other value' do
      subject { vector.reject_values 1, 3 }

      it { is_expected.to be_a DaruLite::Vector }
      its(:to_a) { is_expected.to eq [nil, :a, Float::NAN, nil, Float::NAN] }
      its(:'index.to_a') { is_expected.to eq [12, 14, 15, 16, 17] }
    end

    context 'when resultant vector has only one value' do
      subject { vector.reject_values 1, :a, nil, Float::NAN }

      it { is_expected.to be_a DaruLite::Vector }
      its(:to_a) { is_expected.to eq [3] }
      its(:'index.to_a') { is_expected.to eq [13] }
    end

    context 'when resultant vector has no value' do
      subject { vector.reject_values 1, 3, :a, nil, Float::NAN, 5 }

      it { is_expected.to be_a DaruLite::Vector }
      its(:to_a) { is_expected.to eq [] }
      its(:'index.to_a') { is_expected.to eq [] }
    end

    context 'test caching' do
      let(:vector) { DaruLite::Vector.new [nil]*8, index: 11..18}

      before do
        vector.reject_values nil
        [1, nil, 3, :a, Float::NAN, nil, Float::NAN, 1].each_with_index do |v, pos|
          vector.set_at [pos], v
        end
      end

      context 'reject only nils' do
        subject { vector.reject_values nil }

        it { is_expected.to be_a DaruLite::Vector }
        its(:to_a) { is_expected.to eq [1, 3, :a, Float::NAN, Float::NAN, 1] }
        its(:'index.to_a') { is_expected.to eq [11, 13, 14, 15, 17, 18] }
      end

      context 'reject only float::NAN' do
        subject { vector.reject_values Float::NAN }

        it { is_expected.to be_a DaruLite::Vector }
        its(:to_a) { is_expected.to eq [1, nil, 3, :a, nil, 1] }
        its(:'index.to_a') { is_expected.to eq [11, 12, 13, 14, 16, 18] }
      end

      context 'reject both nil and float::NAN' do
        subject { vector.reject_values nil, Float::NAN }

        it { is_expected.to be_a DaruLite::Vector }
        its(:to_a) { is_expected.to eq [1, 3, :a, 1] }
        its(:'index.to_a') { is_expected.to eq [11, 13, 14, 18] }
      end

      context 'reject any other value' do
        subject { vector.reject_values 1, 3 }

        it { is_expected.to be_a DaruLite::Vector }
        its(:to_a) { is_expected.to eq [nil, :a, Float::NAN, nil, Float::NAN] }
        its(:'index.to_a') { is_expected.to eq [12, 14, 15, 16, 17] }
      end
    end
  end

  context "#only_numerics" do
    subject { vector.only_numerics }

    let(:vector) { DaruLite::Vector.new([1, 2, nil, 3, 4, 's', 'a', nil]) }

    it "returns only numerical or missing data" do
      expect(subject).to eq(
        DaruLite::Vector.new([1, 2, nil, 3, 4, nil], index: [0, 1, 2, 3, 4, 7])
      )
    end
  end
end
