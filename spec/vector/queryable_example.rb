shared_examples_for 'a queryable Vector' do
  describe '#include_values?' do
    context 'only nils' do
      context 'true' do
        let(:vector) { DaruLite::Vector.new [1, 2, 3, :a, 'Unknown', nil] }
        it { expect(vector.include_values? nil).to eq true }
      end

      context 'false' do
        let(:vector) { DaruLite::Vector.new [1, 2, 3, :a, 'Unknown'] }
        it { expect(vector.include_values? nil).to eq false }
      end
    end

    context 'only Float::NAN' do
      context 'true' do
        let(:vector) { DaruLite::Vector.new [1, nil, 2, 3, Float::NAN] }
        it { expect(vector.include_values? Float::NAN).to eq true }
      end

      context 'false' do
        let(:vector) { DaruLite::Vector.new [1, nil, 2, 3] }
        it { expect(vector.include_values? Float::NAN).to eq false }
      end
    end

    context 'both nil and Float::NAN' do
      context 'true with only nil' do
        let(:vector) { DaruLite::Vector.new [1, Float::NAN, 2, 3] }
        it { expect(vector.include_values? nil, Float::NAN).to eq true }
      end

      context 'true with only Float::NAN' do
        let(:vector) { DaruLite::Vector.new [1, nil, 2, 3] }
        it { expect(vector.include_values? nil, Float::NAN).to eq true }
      end

      context 'false' do
        let(:vector) { DaruLite::Vector.new [1, 2, 3] }
        it { expect(vector.include_values? nil, Float::NAN).to eq false }
      end
    end

    context 'any other value' do
      context 'true' do
        let(:vector) { DaruLite::Vector.new [1, 2, 3, 4, nil] }
        it { expect(vector.include_values? 1, 2, 3, 5).to eq true }
      end

      context 'false' do
        let(:vector) { DaruLite::Vector.new [1, 2, 3, 4, nil] }
        it { expect(vector.include_values? 5, 6).to eq false }
      end
    end
  end

  describe "#any?" do
    let(:vector) { DaruLite::Vector.new([1, 2, 3, 4, 5]) }

    it "returns true if block returns true for any one of the elements" do
      expect(vector.any?{ |e| e == 1 }).to eq(true)
    end

    it "returns false if block is false for all elements" do
      expect(vector.any?{ |e| e > 10 }).to eq(false)
    end
  end

  describe "#all?" do
    let(:vector) { DaruLite::Vector.new([1, 2, 3, 4, 5]) }

    it "returns true if block is true for all elements" do
      expect(vector.all? { |e| e < 6 }).to eq(true)
    end

    it "returns false if block is false for any one element" do
      expect(vector.all? { |e| e == 2 }).to eq(false)
    end
  end

  describe '#match' do
    subject { dv.match(regexp) }

    context 'returns matching array for a given regexp' do
      let(:dv)     { DaruLite::Vector.new ['3 days', '5 weeks', '2 weeks'] }
      let(:regexp) { /weeks/ }

      it { is_expected.to eq([false, true, true]) }
    end
  end
end
