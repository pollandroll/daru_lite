shared_examples_for 'a convertible Vector' do |dtype|
  describe "#to_df" do
    subject { vector.to_df }

    let(:vector) do
      DaruLite::Vector.new(['a','b','c'], name: :my_dv, index: ['alpha', 'beta', 'gamma'])
    end

    it 'is a dataframe' do
      expect(subject).to be_a DaruLite::DataFrame
    end

    it 'converts the vector to a single-vector dataframe' do
      expect(subject[:my_dv]).to eq vector
    end

    it 'has the same index as the original vector' do
      expect(subject.index).to eq vector.index
    end

    it 'has the same name as the vector' do
      expect(subject.name).to eq :my_dv
    end
  end

  describe "#to_h" do
    context DaruLite::Index do
      subject { vector.to_h }

      let(:vector) do
        DaruLite::Vector.new(
          [1,2,3,4,5],
          name: :a,
          index: [:one, :two, :three, :four, :five],
          dtype:
        )
      end

      it "returns the vector as a hash" do
        expect(subject).to eq({one: 1, two: 2, three: 3, four: 4, five: 5})
      end
    end

    context DaruLite::MultiIndex do
      pending
      # it "returns vector as a Hash" do
      #   pending
      #   mi = DaruLite::MultiIndex.from_tuples([
      #     [:a,:two,:bar],
      #     [:a,:two,:baz],
      #     [:b,:one,:bar],
      #     [:b,:two,:bar]
      #   ])
      #   vector = DaruLite::Vector.new([1,2,3,4], index: mi, dtype: dtype)
      #   expect(vector.to_h).to eq({
      #     [:a,:two,:bar] => 1,
      #     [:a,:two,:baz] => 2,
      #     [:b,:one,:bar] => 3,
      #     [:b,:two,:bar] => 4
      #   })
      # end
    end
  end

  describe "#to_json" do
    subject { vector.to_json }

    let(:vector) do
      DaruLite::Vector.new(
        [1,2,3,4,5],
        name: :a,
        index: [:one, :two, :three, :four, :five],
        dtype: dtype
      )
    end

    it "returns the vector as json" do
      expect(subject).to eq(vector.to_h.to_json)
    end

  end

  describe "#to_s" do
    let(:vector) { DaruLite::Vector.new(["a", "b"], index: [1, 2], name:) }

    context 'name is nil' do
      let(:name) { nil }

      it 'produces a class, size description' do
        expect(vector.to_s).to eq("#<DaruLite::Vector(2)>")
      end
    end

    context 'name is present' do
      let(:name) { "Test" }

      it 'produces a class, name, size description' do
        expect(vector.to_s).to eq("#<DaruLite::Vector: Test(2)>")
      end
    end

    context 'name is a symbol' do
      let(:name) { :Test }

      it 'produces a class, name, size description' do
        expect(vector.to_s).to eq("#<DaruLite::Vector: Test(2)>")
      end
    end
  end

  describe "#to_matrix" do
    let(:vector) { DaruLite::Vector.new [1, 2, 3, 4, 5, 6] }

    it "converts DaruLite::Vector to a horizontal Ruby Matrix" do
      expect(vector.to_matrix).to eq(Matrix[[1, 2, 3, 4, 5, 6]])
    end

    it "converts DaruLite::Vector to a vertical Ruby Matrix" do
      expect(vector.to_matrix(:vertical)).to eq(Matrix.columns([[1, 2, 3, 4, 5, 6]]))
    end

    it 'raises on wrong axis' do
      expect { vector.to_matrix(:strange) }.to raise_error(ArgumentError)
    end
  end
end
