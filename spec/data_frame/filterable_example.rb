shared_examples_for 'a filterable DataFrame' do
  describe '#uniq' do
    let(:df) { DaruLite::DataFrame.from_csv 'spec/fixtures/duplicates.csv' }

    context 'with no args' do
      subject { df.uniq }

      it 'returns the correct result' do
        expect(subject.shape.first).to eq 30
      end
    end

    context 'given a vector' do
      subject { df.uniq('color') }

      it 'returns the correct result' do
        expect(subject.shape.first).to eq 2
      end
    end

    context 'given an array of vectors' do
      subject { df.uniq("color", "director_name") }

      it 'returns the correct result' do
        expect(subject.shape.first).to eq 29
      end
    end
  end

  describe "#filter" do
    let(:df) { DaruLite::DataFrame.new({ a: [1,2,3], b: [2,3,4] }) }

    context 'avis is row' do
      subject { df.filter(:row) { |r| r[:a] % 2 == 0 } }

      it { is_expected.to eq(df.filter_rows { |r| r[:a] % 2 == 0 }) }
    end

    context 'avis is vector' do
      subject { df.filter(:vector) { |v| v[0] == 1 } }

      it { is_expected.to eq(df.filter_vectors { |v| v[0] == 1 }) }
    end

    context 'avis is unknown' do
      subject { df.filter(:kitten) {} }

      it { expect { subject }.to raise_error ArgumentError, /axis/ }
    end
  end


  describe '#reject_values' do
    let(:df) do
      DaruLite::DataFrame.new({
        a: [1,    2,          3,   nil,        Float::NAN, nil, 1,   7],
        b: [:a,  :b,          nil, Float::NAN, nil,        3,   5,   8],
        c: ['a',  Float::NAN, 3,   4,          3,          5,   nil, 7]
      }, index: 11..18)
    end
    before { df.to_category :b }

    context 'remove nils only' do
      subject { df.reject_values nil }

      it { is_expected.to be_a DaruLite::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [1, 2, 7] }
      its(:'b.to_a') { is_expected.to eq [:a, :b, 8] }
      its(:'c.to_a') { is_expected.to eq ['a', Float::NAN, 7] }
      its(:'index.to_a') { is_expected.to eq [11, 12, 18] }
    end

    context 'remove Float::NAN only' do
      subject { df.reject_values Float::NAN }

      it { is_expected.to be_a DaruLite::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [1, 3, nil, 1, 7] }
      its(:'b.to_a') { is_expected.to eq [:a, nil, 3, 5, 8] }
      its(:'c.to_a') { is_expected.to eq ['a', 3, 5, nil, 7] }
      its(:'index.to_a') { is_expected.to eq [11, 13, 16, 17, 18] }
    end

    context 'remove both nil and Float::NAN' do
      subject { df.reject_values nil, Float::NAN }

      it { is_expected.to be_a DaruLite::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [1, 7] }
      its(:'b.to_a') { is_expected.to eq [:a, 8] }
      its(:'c.to_a') { is_expected.to eq ['a', 7] }
      its(:'index.to_a') { is_expected.to eq [11, 18] }
    end

    context 'any other values' do
      subject { df.reject_values 1, 5 }

      it { is_expected.to be_a DaruLite::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [2, 3, nil, Float::NAN, 7] }
      its(:'b.to_a') { is_expected.to eq [:b, nil, Float::NAN, nil, 8] }
      its(:'c.to_a') { is_expected.to eq [Float::NAN, 3, 4, 3, 7] }
      its(:'index.to_a') { is_expected.to eq [12, 13, 14, 15, 18] }
    end

    context 'when resultant dataframe has one row' do
      subject { df.reject_values 1, 2, 3, 4, 5, nil, Float::NAN }

      it { is_expected.to be_a DaruLite::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [7] }
      its(:'b.to_a') { is_expected.to eq [8] }
      its(:'c.to_a') { is_expected.to eq [7] }
      its(:'index.to_a') { is_expected.to eq [18] }
    end

    context 'when resultant dataframe is empty' do
      subject { df.reject_values 1, 2, 3, 4, 5, 6, 7, nil, Float::NAN }

      it { is_expected.to be_a DaruLite::DataFrame }
      its(:'b.type') { is_expected.to eq :category }
      its(:'a.to_a') { is_expected.to eq [] }
      its(:'b.to_a') { is_expected.to eq [] }
      its(:'c.to_a') { is_expected.to eq [] }
      its(:'index.to_a') { is_expected.to eq [] }
    end
  end

  describe "#keep_row_if" do
    let(:index) { [:one, :two, :three, :four, :five] }
    let(:order) { [:a, :b, :c] }
    let(:df)  do
      DaruLite::DataFrame.new({
          b: [10, 12, 20, 23, 30],
          a: [50, 30, 30, 1, 5],
          c: [10, 20, 30, 40, 50]
        },
        order:,
        index:
      )
    end

    shared_examples_for '#keep_row_if' do
      before { subject }

      it "keeps row if block evaluates to true" do
        expect(df).to eq(expected_df)
      end

      it 'returns correct index' do
        expect(df.index).to eq(expected_index)
      end

      it "all vectors have the same index" do
        expect(df.map(&:index)).to all(eq(expected_index))
      end
    end

    context 'a single row is removed' do
      context DaruLite::Index do
        subject { df.keep_row_if { |row| row.name != :four } }

        let(:expected_index) { DaruLite::Index.new([:one, :two, :three, :five]) }
        let(:expected_df) do
          DaruLite::DataFrame.new(
            { b: [10, 12, 20, 30], a: [50, 30, 30, 5], c: [10, 20, 30, 50] },
            order:,
            index: expected_index
          )
        end

        it_behaves_like '#keep_row_if'
      end

      context DaruLite::CategoricalIndex do
        subject { df.keep_row_if { |row| row.name != :a } }

        let (:index) { DaruLite::CategoricalIndex.new([:a, 1, 1, :a, :c]) }
        let(:expected_index) { DaruLite::CategoricalIndex.new([1, 1, :c]) }
        let(:expected_df) do
          DaruLite::DataFrame.new(
            {
              b: [12, 20, 30],
              a: [30, 30, 5],
              c: [20, 30, 50]
            },
            order:,
            index: expected_index
          )
        end

        it_behaves_like '#keep_row_if'
      end

      context DaruLite::MultiIndex do
        subject { df.keep_row_if { |row| !row.name.include?('two') } }

        let(:index) do
          DaruLite::MultiIndex.from_tuples([[:a, :one], [:a, :two], [:b, :one], [:b, :two], [:c, :one]])
        end
        let(:expected_index) do
          DaruLite::MultiIndex.from_tuples([[:a, :one], [:b, :one], [:c, :one]])
        end
        let(:expected_df) do
          DaruLite::DataFrame.new(
            {
              b: [10, 20, 30],
              a: [50, 30, 5],
              c: [10, 30, 50]
            },
            order:,
            index: expected_index
          )
        end

        it_behaves_like '#keep_row_if'
      end
    end

    context 'several rows are removed' do
      subject { df.keep_row_if { |row| row[:a] % 10 == 0 } }

      context DaruLite::Index do
        let(:expected_index) { DaruLite::Index.new([:one, :two, :three]) }
        let(:expected_df) do
          DaruLite::DataFrame.new(
            { b: [10, 12, 20], a: [50, 30, 30], c: [10, 20, 30] },
            order:,
            index: expected_index
          )
        end

        it_behaves_like '#keep_row_if'
      end

      context DaruLite::CategoricalIndex do
        let (:index) { DaruLite::CategoricalIndex.new([:a, 1, 1, :a, :c]) }
        let(:expected_index) { DaruLite::CategoricalIndex.new([:a, 1, 1]) }
        let(:expected_df) do
          DaruLite::DataFrame.new(
            { b: [10, 12, 20], a: [50, 30, 30], c: [10, 20, 30] },
            order:,
            index: expected_index
          )
        end

        it_behaves_like '#keep_row_if'
      end

      context DaruLite::MultiIndex do
        let(:index) { DaruLite::MultiIndex.from_tuples([[:a, :one], [:a, :two], [:b, :one], [:b, :two], [:c, :one]]) }
        let(:expected_index) do
          DaruLite::MultiIndex.from_tuples([[:a, :one], [:a, :two], [:b, :one]])
        end
        let(:expected_df) do
          DaruLite::DataFrame.new(
            { b: [10, 12, 20], a: [50, 30, 30], c: [10, 20, 30] },
            order:,
            index: expected_index
          )
        end

        it_behaves_like '#keep_row_if'
      end
    end

    # context DaruLite::MultiIndex do
    #   subject { df.keep_row_if { |row| row.name != 'No answer' } }

    #   let(:df) do
    #     order = DaruLite::MultiIndex.from_tuples(
    #       [
    #         [:a, :total],
    #         [:a, "Male"],
    #         [:a, "Female"],
    #         [:a, "Prefer not to answer"],
    #         [:a, "No answer"],
    #         [:b, :total],
    #         [:b, "Male"],
    #         [:b, "Female"],
    #         [:b, "Prefer not to answer"],
    #         [:b, "No answer"],
    #         [:c, :total],
    #         [:c, "Male"],
    #         [:c, "Female"],
    #         [:c, "Prefer not to answer"],
    #         [:c, "No answer"]
    #       ]
    #     )
    #     index = [
    #       :base,
    #       "Single Malt Whisky",
    #       "Blended/ Other Whisky",
    #       "Vodka",
    #       "Cognac",
    #       "Brandy",
    #       "Rum",
    #       "Gin",
    #       "Tequila",
    #       "No answer",
    #       "NET"
    #     ]
    #     DaruLite::DataFrame.new(
    #       [
    #         [0.0, nil, nil, nil, nil, nil, nil, nil, nil],
    #         [nil, nil, nil, nil, nil, nil, nil, nil, nil],
    #         [nil, nil, nil, nil, nil, nil, nil, nil, nil],
    #         [nil, nil, nil, nil, nil, nil, nil, nil, nil],
    #         [nil, nil, nil, nil, nil, nil, nil, nil, nil],
    #         [Float::NAN, nil, nil, nil, nil, nil, nil, nil, nil],
    #         [nil, nil, nil, nil, nil, nil, nil, nil, nil],
    #         [nil, nil, nil, nil, nil, nil, nil, nil, nil],
    #         [nil, nil, nil, nil, nil, nil, nil, nil, nil],
    #         [nil, nil, nil, nil, nil, nil, nil, nil, nil],
    #         [0, nil, nil, nil, nil, nil, nil, nil, nil],
    #         [0, nil, nil, nil, nil, nil, nil, nil, nil],
    #         [0, nil, nil, nil, nil, nil, nil, nil, nil],
    #         [0, nil, nil, nil, nil, nil, nil, nil, nil],
    #         [0, nil, nil, nil, nil, nil, nil, nil, nil],
    #       ],
    #       index:,
    #       order:
    #     )
    #   end

    #   it "all vectors have the same index" do
    #     subject
    #     expect(df.map(&:index)).to all(eq(df.index))
    #   end
    # end
  end

  describe "#keep_vector_if" do
    it "keeps vector if block evaluates to true" do
      df.keep_vector_if do |vector|
        vector == [1,2,3,4,5].dv(nil, [:one, :two, :three, :four, :five])
      end

      expect(df).to eq(DaruLite::DataFrame.new({a: [1,2,3,4,5]}, order: [:a],
        index: [:one, :two, :three, :four, :five]))
    end
  end

  describe "#filter_vectors" do
    context DaruLite::Index do
      subject { df.filter_vectors { |vector| vector[0] == 1 } }

      let(:df) { DaruLite::DataFrame.new({ a: [1,2,3], b: [2,3,4] }) }

      it "filters vectors" do
        expect(subject).to eq(DaruLite::DataFrame.new({a: [1,2,3]}))
      end
    end
  end

  describe "#filter_rows" do
    context DaruLite::Index do
      subject { df.filter_rows { |r| r[:a] != 2 } }

      let(:df) { DaruLite::DataFrame.new a: 1..3, b: 4..6 }

      it "preserves names of vectors" do
        expect(subject[:a].name).to eq(df[:a].name)
      end

      context "when specified no index" do
        subject { df.filter_rows { |row| row[:a] % 2 == 0 } }

        let(:df) { DaruLite::DataFrame.new({ a: [1,2,3], b: [2,3,4] }) }

        it "filters rows" do
          expect(subject).to eq(DaruLite::DataFrame.new({ a: [2], b: [3] }, order: [:a, :b], index: [1]))
        end
      end

      context "when specified numerical index" do
        subject { df.filter_rows { |row| row[:a] % 2 == 0 } }

        let(:df) { DaruLite::DataFrame.new({ a: [1,2,3], b: [2,3,4] }, index: [1,2,3]) }

        it "filters rows" do
          expect(subject).to eq(DaruLite::DataFrame.new({ a: [2], b: [3] }, order: [:a, :b], index: [2]))
        end
      end
    end
  end

  context "#filter_vector" do
    subject { df.filter_vector(:id) { |c| c[:id] == 2 or c[:id] == 4 } }

    let(:df) do
      DaruLite::DataFrame.new(
        {
          id: DaruLite::Vector.new([1, 2, 3, 4, 5]),
          name: DaruLite::Vector.new(%w(Alex Claude Peter Franz George)),
          age: DaruLite::Vector.new([20, 23, 25, 27, 5]),
          city: DaruLite::Vector.new(['New York', 'London', 'London', 'Paris', 'Tome']),
          a1: DaruLite::Vector.new(['a,b', 'b,c', 'a', nil, 'a,b,c'])
        },
        order: [:id, :name, :age, :city, :a1]
      )
    end

    it "creates new vector with the data of a given field for which block returns true" do
      expect(subject).to eq(DaruLite::Vector.new([2,4]))
    end
  end
end
