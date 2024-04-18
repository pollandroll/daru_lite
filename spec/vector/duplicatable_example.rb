shared_examples_for 'a duplicatable Vector' do
  describe "#dup" do
    subject { vector.dup }

    let(:vector) do
      DaruLite::Vector.new([1, 2], name: :yoda, index: [:happy, :lightsaber])
    end

    it "copies the original data" do
      expect(subject.send(:data)).to eq([1,2])
    end

    it "creates a new data object" do
      expect(subject.send(:data).object_id).not_to eq(vector.send(:data).object_id)
    end

    it "copies the name" do
      expect(subject.name).to eq(:yoda)
    end

    it "copies the original index" do
      expect(subject.index).to eq(DaruLite::Index.new([:happy, :lightsaber]))
    end

    it "creates a new index object" do
      expect(subject.index.object_id).not_to eq(vector.index.object_id)
    end
  end

  describe "#clone_structure" do
    subject { vector.clone_structure }
    context DaruLite::Index do
      let(:vector) do
        DaruLite::Vector.new([1, 2, 3, 4, 5], index: [:a,:b,:c,:d,:e])
      end

      it "clones a vector with its index and fills it with nils" do
        expect(subject).to eq(
          DaruLite::Vector.new([nil, nil, nil, nil, nil], index: [:a,:b,:c,:d,:e])
        )
      end
    end

    context DaruLite::MultiIndex do
      pending
    end
  end
end
