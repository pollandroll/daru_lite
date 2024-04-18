shared_examples_for 'an indexable Vector' do |dtype|
  describe "#index_of" do
    context DaruLite::Index do
      let(:vector) do
        DaruLite::Vector.new(
          [1,2,3,4,5],
          name: :a,
          index: [:one, :two, :three, :four, :five],
          dtype:
        )
      end
      it "returns index of specified value" do
        expect(vector.index_of(1)).to eq(:one)
      end
    end

    context DaruLite::MultiIndex do
      let(:vector) { DaruLite::Vector.new([1,2,3,4], index: multi_index, dtype:) }
      let(:multi_index) do
        DaruLite::MultiIndex.from_tuples([
          [:a,:two,:bar],
          [:a,:two,:baz],
          [:b,:one,:bar],
          [:b,:two,:bar]
        ])
      end

      it "returns tuple of specified value" do
        expect(vector.index_of(3)).to eq([:b,:one,:bar])
      end
    end
  end

  describe "#index=" do
    subject { vector.index = new_index }

    let(:vector) { DaruLite::Vector.new([1,2,3,4,5]) }

    context "new index is an Index" do
      before { subject }

      let(:new_index) { DaruLite::DateTimeIndex.date_range(start: '2012', periods: 5) }

      it 'returns the new index' do
        expect(subject).to eq(new_index)
      end

      it "simply reassigns index" do
        expect(vector.index.class).to eq(DaruLite::DateTimeIndex)
        expect(vector['2012-1-1']).to eq(1)
      end
    end

    context "new index is an array" do
      before { subject }

      let(:new_index) { [5, 4, 3, 2, 1] }

      it "accepts an array as index" do
        expect(vector.index.class).to eq(DaruLite::Index)
        expect(vector[5]).to eq(1)
      end
    end

    context "new index is a range" do
      before { subject }

      let(:new_index) { 'a'..'e' }

      it "accepts an range as index" do
        expect(vector.index.class).to eq(DaruLite::Index)
        expect(vector['a']).to eq(1)
      end
    end

    context "new index has a different size" do
      let(:new_index) { DaruLite::Index.new([4,2,6]) }

      it "raises error for index size != vector size" do
        expect { subject }.to raise_error(
          ArgumentError, 'Size of supplied index 3 does not match size of Vector'
        )
      end
    end
  end

  describe "#reindex!" do
    subject { vector.reindex!(index) }

    let(:vector) { DaruLite::Vector.new([1, 2, 3, 4, 5]) }
    let(:index) { DaruLite::Index.new([3, 4, 1, 0, 6]) }

    before { subject }

    it "intelligently reindexes" do
      expect(vector).to eq(DaruLite::Vector.new([4, 5, 2, 1, nil], index:))
    end
  end

  describe "#reindex" do
    subject { vector.reindex(index) }

    let(:vector) { DaruLite::Vector.new([1, 2, 3, 4, 5]) }
    let(:index) { DaruLite::Index.new([3, 4, 1, 0, 6]) }

    it "intelligently reindexes" do
      expect(subject).to eq(DaruLite::Vector.new([4, 5, 2, 1, nil], index:))
    end
  end

  describe '#indexes' do
    context DaruLite::Index do
      subject { vector.indexes 1, 2, nil, Float::NAN }

      let(:vector) do
        DaruLite::Vector.new(
          [1, 2, 1, 2, 3, nil, nil, Float::NAN],
          index: 11..18
        )
      end

      it { is_expected.to be_a Array }
      it { is_expected.to eq [11, 12, 13, 14, 16, 17, 18] }
    end

    context DaruLite::MultiIndex do
      subject { vector.indexes 1, 2, Float::NAN }

      let(:mi) do
        DaruLite::MultiIndex.from_tuples([
          ['M', 2000],
          ['M', 2001],
          ['M', 2002],
          ['M', 2003],
          ['F', 2000],
          ['F', 2001],
          ['F', 2002],
          ['F', 2003]
        ])
      end
      let(:vector) { DaruLite::Vector.new([1, 2, 1, 2, 3, nil, nil, Float::NAN], index: mi) }

      it { is_expected.to be_a Array }
      it { is_expected.to eq(
        [
          ['M', 2000],
          ['M', 2001],
          ['M', 2002],
          ['M', 2003],
          ['F', 2003]
        ]) }
    end
  end

  describe "#reset_index!" do
    subject { vector.reset_index! }

    context 'after rejecting initial values' do
      let(:vector) do
        v = DaruLite::Vector.new([1, 2, 3, 4, 5, nil, nil, 4, nil])
        v.reject_values(*DaruLite::MISSING_VALUES)
      end

      it "resets any index to a numerical serialized index" do
        expect(subject).to eq(DaruLite::Vector.new([1, 2, 3, 4, 5, 4]))
        expect(subject.index).to eq(DaruLite::Index.new([0, 1, 2, 3, 4, 5]))
      end
    end

    context 'when vector is indexed' do
      let(:vector) do
        DaruLite::Vector.new([1, 2, 3, 4, 5], index: [:a, :b, :c, :d, :e])
      end

      it "resets any index to a numerical serialized index" do
        expect(subject.index).to eq(DaruLite::Index.new([0, 1, 2, 3, 4]))
      end
    end
  end

  describe "#detach_index" do
    subject { vector.detach_index }

    let(:vector) do
      DaruLite::Vector.new(
        [1, 2, 3, 4, 5, 6],
        index: ['a', 'b', 'c', 'd', 'e', 'f'],
        name: :values
      )
    end

    it "creates a DataFrame with first Vector as index and second as values of the Vector" do
      expect(vector.detach_index).to eq(
        DaruLite::DataFrame.new(
          index: ['a', 'b', 'c', 'd', 'e', 'f'],
          values: [1, 2, 3, 4, 5, 6]
        )
      )
    end
  end
end
