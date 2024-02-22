shared_examples_for 'a convertible DataFrame' do
  describe '#create_sql' do
    subject { df.create_sql('foo') }

    let(:df) do
      DaruLite::DataFrame.new(
        {
          a: [1,2,3],
          b: ['test', 'me', 'please'],
          c: ['2015-06-01', '2015-06-02', '2015-06-03']
        },
        name: 'test'
      )
    end

    it { is_expected.to eq %Q{
      |CREATE TABLE foo (a INTEGER,
      | b VARCHAR (255),
      | c DATE) CHARACTER SET=UTF8;
    }.unindent }
  end

  describe '#to_df' do
    subject { df.to_df }

    it { is_expected.to eq(df) }
  end

  describe "#to_matrix" do
    subject { df.to_matrix }

    let(:df) do
      DaruLite::DataFrame.new(
        {
          b: [11,12,13,14,15],
          a: [1,2,3,4,5],
          c: [11,22,33,44,55],
          d: [5,4,nil,2,1],
          e: ['this', 'has', 'string','data','too']
        },
        order: [:a, :b, :c,:d,:e],
        index: [:one, :two, :three, :four, :five]
      )
    end

    it "concats numeric non-nil vectors to Matrix" do
      expect(subject).to eq(Matrix[
        [1,11,11,5],
        [2,12,22,4],
        [3,13,33,nil],
        [4,14,44,2],
        [5,15,55,1]
      ])
    end
  end

  describe "#to_a" do
    subject { df.to_a }

    context DaruLite::Index do
      it "converts DataFrame into array of hashes" do
        expect(subject).to eq(
          [
            [
              {a: 1, b: 11, c: 11},
              {a: 2, b: 12, c: 22},
              {a: 3, b: 13, c: 33},
              {a: 4, b: 14, c: 44},
              {a: 5, b: 15, c: 55}
            ],
            [
              :one, :two, :three, :four, :five
            ]
          ])
      end
    end

    context DaruLite::MultiIndex do
      pending
    end
  end

  describe '#to_json' do
    subject { JSON.parse(json) }

    let(:df) do
      DaruLite::DataFrame.new(
        { a: [1,2,3], b: [3,4,5], c: [6,7,8]},
        index: [:one, :two, :three],
        name: 'test'
      )
    end

    context 'with index' do
      let(:json) { df.to_json(false) }
      # FIXME: is it most reasonable we can do?.. -- zverok
      # For me, more resonable thing would be something like
      #
      # [
      #   {"index" => "one"  , "a"=>1, "b"=>3, "c"=>6},
      #   {"index" => "two"  , "a"=>2, "b"=>4, "c"=>7},
      #   {"index" => "three", "a"=>3, "b"=>5, "c"=>8}
      # ]
      #
      # Or maybe
      #
      # [
      #   ["one"  , {"a"=>1, "b"=>3, "c"=>6}],
      #   ["two"  , {"a"=>2, "b"=>4, "c"=>7}],
      #   ["three", {"a"=>3, "b"=>5, "c"=>8}]
      # ]
      #
      # Or even
      #
      # {
      #   "one"   => {"a"=>1, "b"=>3, "c"=>6},
      #   "two"   => {"a"=>2, "b"=>4, "c"=>7},
      #   "three" => {"a"=>3, "b"=>5, "c"=>8}
      # }
      #
      it { is_expected.to eq(
        [
          [
            {"a"=>1, "b"=>3, "c"=>6},
            {"a"=>2, "b"=>4, "c"=>7},
            {"a"=>3, "b"=>5, "c"=>8}
          ],
          ["one", "two", "three"]
        ]
      )}
    end

    context 'without index' do
      let(:json) { df.to_json(true) }

      it { is_expected.to eq(
        [
          {"a"=>1, "b"=>3, "c"=>6},
          {"a"=>2, "b"=>4, "c"=>7},
          {"a"=>3, "b"=>5, "c"=>8}
        ]
      )}
    end
  end

  describe "#to_h" do
    subject { df.to_h }

    it "converts to a hash" do
      expect(subject).to eq(
        {
          a: DaruLite::Vector.new([1,2,3,4,5],
            index: [:one, :two, :three, :four, :five]),
          b: DaruLite::Vector.new([11,12,13,14,15],
            index: [:one, :two, :three, :four, :five]),
          c: DaruLite::Vector.new([11,22,33,44,55],
            index: [:one, :two, :three, :four, :five])
        }
      )
    end
  end

  describe '#to_s' do
    subject { df.to_s }

    it 'produces a class, size description' do
      expect(subject).to eq "#<DaruLite::DataFrame(5x3)>"
    end

    it 'produces a class, name, size description' do
      df.name = "Test"
      expect(subject).to eq "#<DaruLite::DataFrame: Test(5x3)>"
    end

    it 'produces a class, name, size description when the name is a symbol' do
      df.name = :Test
      expect(subject).to eq "#<DaruLite::DataFrame: Test(5x3)>"
    end
  end
end
