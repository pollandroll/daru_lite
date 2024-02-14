describe DaruLite::Vector do
  let(:dv1) { described_class.new(values1, name: :boozy, index: indexes1) }
  let(:dv2) { described_class.new(values2, name: :mayer, index: indexes2) }
  let(:with_md1) do
    described_class.new([1, 2, 3, nil, 5, nil], name: :missing, index: indexes_with_md1)
  end
  let(:with_md2) do
    described_class.new([1, 2, 3, nil, 5, nil], name: :missing, index: [:obi, :wan, :corona, :a, :b, :c])
  end
  let(:values1) { [1, 2, 3, 4] }
  let(:values2) { [1, 2, 3, 4] }
  let(:indexes1) { [:bud, :kf, :henie, :corona] }
  let(:indexes2) { [:obi, :wan, :kf, :corona] }
  let(:indexes1_and_2) { [:bud, :corona, :henie, :kf, :obi, :wan] }
  let(:indexes_with_md1) { [:a, :b, :c, :obi, :wan, :corona] }
  let(:indexes_with_md1_and_2) { [:a, :b, :c, :corona, :obi, :wan] }

  describe "#+" do
    it "adds matching indexes of the other vector" do
      expect(dv1 + dv2).to eq(
        DaruLite::Vector.new([nil, 8, nil, 5, nil, nil], name: :boozy, index: indexes1_and_2)
      )
    end

    it "adds number to each element of the entire vector" do
      expect(dv1 + 5).to eq(DaruLite::Vector.new(values1.map { |v| v + 5 }, name: :boozy, index: indexes1))
    end

    it "does not add when a number is being added" do
      expect(with_md1 + 1).to eq(
        DaruLite::Vector.new([2, 3, 4, nil, 6, nil], name: :missing, index: indexes_with_md1)
      )
    end

    it "puts a nil when one of the operands is nil" do
      expect(with_md1 + with_md2).to eq(
        DaruLite::Vector.new([nil, 7, nil, nil, nil, 7], name: :missing, index: indexes_with_md1_and_2)
      )
    end

    context 'when vectors have numeric and non-numeric indexes' do
      let(:indexes1) { nil }
      let(:indexes2) { [:a, :b, :c, :d] }

      it "appropriately adds vectors with numeric and non-numeric indexes" do
        expect(dv1 + dv2).to eq(DaruLite::Vector.new(Array.new(6), index: [0, 1, 2, 3] + indexes2))
      end
    end

    context 'when index contains symbols and strings' do
      let(:indexes1) { [:bud, 'kf', :henie, :corona] }
      let(:indexes2) { [:obi, :wan, 'kf', :corona] }

      it "adds matching indexes of the other vector" do
        expect(dv1 + dv2).to eq(
          DaruLite::Vector.new([nil, 8, nil, 5, nil, nil], name: :boozy, index: [:bud, :corona, :henie, 'kf', :obi, :wan])
        )
      end
    end
  end

  describe "#-" do
    it "subtracts matching indexes of the other vector" do
      expect(dv1 - dv2).to eq(
        DaruLite::Vector.new([nil, 0, nil, -1, nil, nil], name: :boozy, index: indexes1_and_2)
      )
    end

    it "subtracts number from each element of the entire vector" do
      expect(dv1 - 5).to eq(DaruLite::Vector.new(values1.map { |v| v - 5 }, name: :boozy, index: indexes1))
    end
  end

  describe "#*" do
    it "multiplies matching indexes of the other vector" do
      expect(dv1 * dv2).to eq(
        DaruLite::Vector.new([nil, 16, nil, 6, nil, nil], name: :boozy, index: indexes1_and_2)
      )
    end

    it "multiplies number to each element of the entire vector" do
      expect(dv1 * 5).to eq(DaruLite::Vector.new(values1.map { |v| v * 5 }, name: :boozy, index: indexes1))
    end
  end

  describe "#\/" do
    let(:values2) { [1.0, 2.0, 3.0, 4.0] }

    it "divides matching indexes of the other vector" do
      expect(dv1 / dv2).to eq(
        DaruLite::Vector.new([nil, 1.0, nil, 2 / 3.to_f, nil, nil], name: :boozy, index: indexes1_and_2)
      )
    end

    it "divides number from each element of the entire vector" do
      expect(dv1 / 5.0).to eq(DaruLite::Vector.new(values1.map { |v| v / 5.0 }, name: :boozy, index: indexes1))
    end
  end

  describe "#%" do
    it "applies % to matching indexes of the other vector" do
      expect(dv1 % dv2).to eq(DaruLite::Vector.new([nil, 0, nil, 2, nil, nil], name: :boozy, index: indexes1_and_2))
    end

    it "applies % for each element of the entire vector" do
      expect(dv1 % 5).to eq(
        DaruLite::Vector.new(values1.map { |v| v % 5 }, name: :boozy, index: indexes1)
      )
    end
  end

  describe "#**" do
    it "applies ** to matching indexes of the other vector" do
      expect(dv1 ** dv2).to eq(DaruLite::Vector.new([nil, 256, nil, 8, nil, nil], name: :boozy, index: indexes1_and_2))
    end

    it "applies ** for each element of the entire vector" do
      expect(dv1 ** 5).to eq(DaruLite::Vector.new(values1.map { |v| v ** 5 }, name: :boozy, index: indexes1))
    end
  end

  describe "#exp" do
    it "calculates exp of all numbers" do
      expect(with_md1.exp.round(3)).to eq(
        DaruLite::Vector.new(
          [2.718281828459045, 7.38905609893065, 20.085536923187668, nil, 148.4131591025766, nil],
          index: indexes_with_md1,
          name: :missing
        ).round(3)
      )
    end
  end

  describe "#add" do
    it "adds two vectors with nils as 0 if skipnil is true" do
      expect(with_md1.add(with_md2, skipnil: true)).to eq(
        DaruLite::Vector.new([1, 7, 3, 3, 1, 7], name: :missing, index: indexes_with_md1_and_2)
      )
    end

    it "adds two vectors same as :+ if skipnil is false" do
      expect(with_md1.add(with_md2, skipnil: false)).to eq(
        DaruLite::Vector.new([nil, 7, nil, nil, nil, 7], name: :missing, index: indexes_with_md1_and_2)
      )
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
