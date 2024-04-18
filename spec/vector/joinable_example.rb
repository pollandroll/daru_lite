shared_examples_for 'a joinable Vector' do |dtype|
  describe "#concat" do
    let(:vector) do
      DaruLite::Vector.new(
        [1, 2, 3, 4, 5],
        name: :yoga,
        index: [:warwick, :thompson, :jackson, :fender, :esp],
        dtype:
      )
    end

    it "concatenates a new element at the end of vector with index" do
      vector.concat(6, :ibanez)

      expect(vector.index)   .to eq(
        DaruLite::Index.new([:warwick, :thompson, :jackson, :fender, :esp, :ibanez]))
      expect(vector[:ibanez]).to eq(6)
      expect(vector[5])      .to eq(6)
    end

    it "raises error if index not specified" do
      expect { vector.concat(6) }.to raise_error
    end
  end
end
