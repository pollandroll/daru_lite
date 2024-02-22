shared_examples_for 'a calculatable DataFrame' do
  context "#vector_sum" do
    let(:df) do
      a1 = DaruLite::Vector.new [1, 2, 3, 4, 5, nil, nil]
      a2 = DaruLite::Vector.new [10, 10, 20, 20, 20, 30, nil]
      b1 = DaruLite::Vector.new [nil, 1, 1, 1, 1, 2, nil]
      b2 = DaruLite::Vector.new [2, 2, 2, nil, 2, 3, nil]
      DaruLite::DataFrame.new({ a1:, a2:, b1:, b2: })
    end

    it "calculates complete vector sum" do
      expect(df.vector_sum).to eq(DaruLite::Vector.new [nil, 15, 26, nil, 28, nil, nil])
    end

    it "ignores nils if skipnil is true" do
      expect(df.vector_sum skipnil: true).to eq(DaruLite::Vector.new [13, 15, 26, 25, 28, 35, 0])
    end

    it "calculates partial vector sum" do
      a = df.vector_sum([:a1, :a2])
      b = df.vector_sum([:b1, :b2])

      expect(a).to eq(DaruLite::Vector.new [11, 12, 23, 24, 25, nil, nil])
      expect(b).to eq(DaruLite::Vector.new [nil, 3, 3, nil, 3, 5, nil])
    end
  end

  describe "#vector_mean" do
    let(:df) do
      a1 = DaruLite::Vector.new [1, 2, 3, 4, 5, nil]
      a2 = DaruLite::Vector.new [10, 10, 20, 20, 20, 30]
      b1 = DaruLite::Vector.new [nil, 1, 1, 1, 1, 2]
      b2 = DaruLite::Vector.new [2, 2, 2, nil, 2, 3]
      c  = DaruLite::Vector.new [nil, 2, 4, 2, 2, 2]
      DaruLite::DataFrame.new({ a1:, a2:, b1:, b2:, c: })
    end

    it "calculates complete vector mean" do
      expect(df.vector_mean).to eq(
        DaruLite::Vector.new [nil, 3.4, 6, nil, 6.0, nil]
      )
    end
  end

  describe "#compute" do
    let(:vnumeric) { DaruLite::Vector.new [0, 0, 1, 4] }
    let(:vsum) { DaruLite::Vector.new [1 + 4 + 10.0, 2 + 3 + 20.0, 3 + 2 + 30.0, 4 + 1 + 40.0] }
    let(:vmult) { DaruLite::Vector.new [1 * 4, 2 * 3, 3 * 2, 4 * 1] }
    let(:df) do
      v1 = DaruLite::Vector.new [1, 2, 3, 4]
      v2 = DaruLite::Vector.new [4, 3, 2, 1]
      v3 = DaruLite::Vector.new [10, 20, 30, 40]

      DaruLite::DataFrame.new({ v1:, v2:, v3: })
    end

    it "performs a computation when supplied in a string" do
      expect(df.compute("v1/v2")).to eq(vnumeric)
      expect(df.compute("v1+v2+v3")).to eq(vsum)
      expect(df.compute("v1*v2")).to eq(vmult)
    end
  end

  describe "#vector_by_calculation" do
    subject { df.vector_by_calculation { a + b + c } }

    let(:df) do
      a1 = DaruLite::Vector.new([1, 2, 3, 4, 5, 6, 7])
      a2 = DaruLite::Vector.new([10, 20, 30, 40, 50, 60, 70])
      a3 = DaruLite::Vector.new([100, 200, 300, 400, 500, 600, 700])
      DaruLite::DataFrame.new({ :a => a1, :b => a2, :c => a3 })
    end

    it "DSL for returning vector of each calculation" do
      expect(subject).to eq(DaruLite::Vector.new([111, 222, 333, 444, 555, 666, 777]))
    end
  end

  describe "#vector_count_characters" do
    subject { df.vector_count_characters }
    let(:df) do
      a1 = DaruLite::Vector.new( [1, 'abcde', 3, 4, 5, nil])
      a2 = DaruLite::Vector.new( [10, 20.3, 20, 20, 20, 30])
      b1 = DaruLite::Vector.new( [nil, '343434', 1, 1, 1, 2])
      b2 = DaruLite::Vector.new( [2, 2, 2, nil, 2, 3])
      c  = DaruLite::Vector.new([nil, 2, 'This is a nice example', 2, 2, 2])

      DaruLite::DataFrame.new({ a1:, a2:, b1:, b2:, c: })
    end

    it "returns correct values" do
      expect(subject).to eq(DaruLite::Vector.new([4, 17, 27, 5, 6, 5]))
    end
  end

  describe "#summary" do
    subject { df.summary }

    context "DataFrame" do
      let(:df) do
        DaruLite::DataFrame.new(
          { a: [1,2,5], b: [1,2,"string"] },
          order: [:a, :b],
          index: [:one, :two, :three],
          name: 'frame'
        )
      end

      it { is_expected.to eq %Q{
            |= frame
            |  Number of rows: 3
            |  Element:[a]
            |  == a
            |    n :3
            |    non-missing:3
            |    median: 2
            |    mean: 2.6667
            |    std.dev.: 2.0817
            |    std.err.: 1.2019
            |    skew: 0.2874
            |    kurtosis: -2.3333
            |  Element:[b]
            |  == b
            |    n :3
            |    non-missing:3
            |    factors: 1,2,string
            |    mode: 1,2,string
            |    Distribution
            |                 1       1 100.00%
            |                 2       1 100.00%
            |            string       1 100.00%
        }.unindent }
    end
  end
end
