describe Daru::Vector do
  let(:dv1) { described_class.new([1, 2, 3, 4], name: :boozy, index: [:bud, :kf, :henie, :corona]) }
  let(:dv2) { described_class.new([1, 2, 3, 4], name: :mayer, index: [:obi, :wan, :kf, :corona]) }
  let(:with_md1) do
    described_class.new([1, 2, 3, nil, 5, nil], name: :missing, index: [:a, :b, :c, :obi, :wan, :corona])
  end
  let(:with_md2) do
    described_class.new([1, 2, 3, nil, 5, nil], name: :missing, index: [:obi, :wan, :corona, :a, :b, :c])
  end

  describe "#+" do
    it "adds matching indexes of the other vector" do
      expect(dv1 + dv2).to eq(
        Daru::Vector.new([nil, 8, nil, 5, nil, nil], name: :boozy, index: [:bud, :corona, :henie, :kf, :obi, :wan])
      )
    end

    it "adds number to each element of the entire vector" do
      expect(dv1 + 5).to eq(Daru::Vector.new([6, 7, 8, 9], name: :boozy, index: [:bud, :kf, :henie, :corona]))
    end

    it "does not add when a number is being added" do
      expect(with_md1 + 1).to eq(
        Daru::Vector.new([2, 3, 4, nil, 6, nil], name: :missing, index: [:a, :b, :c, :obi, :wan, :corona])
      )
    end

    it "puts a nil when one of the operands is nil" do
      expect(with_md1 + with_md2).to eq(
        Daru::Vector.new([nil, 7, nil, nil, nil, 7], name: :missing, index: [:a, :b, :c, :corona, :obi, :wan])
      )
    end

    context 'when vectors have numeric and non-numeric indexes' do
      let(:dv1) { described_class.new([1, 2, 3]) }
      let(:dv2) { described_class.new([1, 2, 3], index: [:a, :b, :c]) }

      it "appropriately adds vectors with numeric and non-numeric indexes" do
        expect(dv1 + dv2).to eq(Daru::Vector.new(Array.new(6), index: [0, 1, 2, :a, :b, :c]))
      end
    end

    context 'when index contains symbols and strings' do
      let(:dv1) { described_class.new([1, 2, 3, 4], name: :boozy, index: [:bud, 'kf', :henie, :corona]) }
      let(:dv2) { described_class.new([1, 2, 3, 4], name: :mayer, index: [:obi, :wan, 'kf', :corona]) }

      it "adds matching indexes of the other vector" do
        expect(dv1 + dv2).to eq(
          Daru::Vector.new([nil,8,nil,5,nil,nil], name: :boozy, index: [:bud, :corona, :henie, 'kf', :obi, :wan])
        )
      end
    end
  end

  describe "#-" do
    it "subtracts matching indexes of the other vector" do
      expect(dv1 - dv2).to eq(Daru::Vector.new([nil,0,nil,-1,nil,nil], name: :boozy, index: [:bud,:corona,:henie,:kf,:obi,:wan]))
    end

    it "subtracts number from each element of the entire vector" do
      expect(dv1 - 5).to eq(Daru::Vector.new [-4,-3,-2,-1], name: :boozy, index: [:bud, :kf, :henie, :corona])
    end
  end

  describe "#*" do
    it "multiplies matching indexes of the other vector" do

    end

    it "multiplies number to each element of the entire vector" do

    end
  end

  describe "#\/" do
    it "divides matching indexes of the other vector" do

    end

    it "divides number from each element of the entire vector" do

    end
  end

  describe "#%" do

  end

  describe "#**" do

  end

  describe "#exp" do
    it "calculates exp of all numbers" do
      expect(with_md1.exp.round(3)).to eq(Daru::Vector.new([2.718281828459045,
        7.38905609893065, 20.085536923187668, nil, 148.4131591025766, nil], index:
        [:a, :b, :c, :obi, :wan, :corona], name: :missing).round(3))
    end
  end

  describe "#add" do
    it "adds two vectors with nils as 0 if skipnil is true" do
      expect(with_md1.add(with_md2, skipnil: true)).to eq(Daru::Vector.new(
        [1, 7, 3, 3, 1, 7],
        name: :missing,
        index: [:a, :b, :c, :corona, :obi, :wan]))
    end

    it "adds two vectors same as :+ if skipnil is false" do
      expect(with_md1.add(with_md2, skipnil: false)).to eq(Daru::Vector.new(
        [nil, 7, nil, nil, nil, 7],
        name: :missing,
        index: [:a, :b, :c, :corona, :obi, :wan]))
    end
  end

  describe "#abs" do
    it "calculates abs value" do
      with_md1.abs
    end
  end

  describe "#sqrt" do
    it "calculates sqrt" do
      with_md1.sqrt
    end
  end

  describe "#round" do
    it "rounds to given precision" do
      with_md1.round(2)
    end
  end
end
