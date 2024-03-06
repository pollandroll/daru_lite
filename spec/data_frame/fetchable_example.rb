shared_examples_for 'a fetchable DataFrame' do
  describe "#[]" do
    context DaruLite::Index do
      let(:df) do
        DaruLite::DataFrame.new(
          {
            b: [11,12,13,14,15],
            a: [1,2,3,4,5],
            c: [11,22,33,44,55]
          },
          order: [:a, :b, :c],
          index: [:one, :two, :three, :four, :five]
        )
      end

      it "returns a Vector" do
        expect(df[:a]).to eq([1,2,3,4,5].dv(:a, [:one, :two, :three, :four, :five]))
      end

      it "returns a Vector by default" do
        expect(df[:a]).to eq(DaruLite::Vector.new([1,2,3,4,5], name: :a,
          index: [:one, :two, :three, :four, :five]))
      end

      it "returns a DataFrame" do
        temp = DaruLite::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]},
          order: [:a, :b], index: [:one, :two, :three, :four, :five])

        expect(df[:a, :b]).to eq(temp)
      end

      it "accesses vector with Integer index" do
        expect(df[0]).to eq([1,2,3,4,5].dv(:a, [:one, :two, :three, :four, :five]))
      end

      it "returns a subset of DataFrame when specified range" do
        subset = df[:b..:c]
        expect(subset).to eq(DaruLite::DataFrame.new({
          b: [11,12,13,14,15],
          c: [11,22,33,44,55]
          }, index: [:one, :two, :three, :four, :five]))
      end

      it 'accepts axis parameter as a last argument' do
        expect(df[:a, :vector]).to eq df[:a]
        expect(df[:one, :row]).to eq [1, 11, 11].dv(:one, [:a, :b, :c])
      end
    end

    context DaruLite::MultiIndex do
      it "accesses vector with an integer index" do
        expect(df_mi[0]).to eq(
          DaruLite::Vector.new(vector_arry1, index: multi_index))
      end

      it "returns a vector when specifying full tuple" do
        expect(df_mi[:a, :one, :bar]).to eq(
          DaruLite::Vector.new(vector_arry1, index: multi_index))
      end

      it "returns DataFrame when specified first layer of MultiIndex" do
        sub_order = DaruLite::MultiIndex.from_tuples([
          [:one, :bar],
          [:two, :baz]
          ])
        expect(df_mi[:a]).to eq(
          DaruLite::DataFrame.new([vector_arry1, vector_arry2], index: multi_index, order: sub_order)
        )
      end

      it "returns a Vector if the last level of MultiIndex is tracked" do
        expect(df_mi[:a, :one, :bar]).to eq(
          DaruLite::Vector.new(vector_arry1, index: multi_index)
        )
      end
    end
  end

  describe "#at" do
    context DaruLite::Index do
      let(:idx) { DaruLite::Index.new [:a, :b, :c] }
      let(:df) do
        DaruLite::DataFrame.new({
          1 => 1..3,
          a: 'a'..'c',
          b: 11..13
        }, index: idx)
      end

      context "single position" do
        subject { df.at 1 }

        it { is_expected.to be_a DaruLite::Vector }
        its(:size) { is_expected.to eq 3 }
        its(:to_a) { is_expected.to eq ['a', 'b', 'c'] }
        its(:index) { is_expected.to eq idx }
      end

      context "multiple positions" do
        subject { df.at 0, 2 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:shape) { is_expected.to eq [3, 2] }
        its(:index) { is_expected.to eq idx }
        it { expect(df[1].to_a).to eq [1, 2, 3] }
        its(:'b.to_a') { is_expected.to eq [11, 12, 13] }
      end

      context "single invalid position" do
        it { expect { df. at 3 }.to raise_error IndexError }
      end

      context "multiple invalid positions" do
        it { expect { df.at 2, 3 }.to raise_error IndexError }
      end

      context "range" do
        subject { df.at 0..1 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:shape) { is_expected.to eq [3, 2] }
        its(:index) { is_expected.to eq idx }
        it { expect(df[1].to_a).to eq [1, 2, 3] }
        its(:'a.to_a') { is_expected.to eq ['a', 'b', 'c'] }
      end

      context "range with negative end" do
        subject { df.at 0..-2 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:shape) { is_expected.to eq [3, 2] }
        its(:index) { is_expected.to eq idx }
        it { expect(df[1].to_a).to eq [1, 2, 3] }
        its(:'a.to_a') { is_expected.to eq ['a', 'b', 'c'] }
      end

      context "range with single element" do
        subject { df.at 1..1 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:shape) { is_expected.to eq [3, 1] }
        its(:index) { is_expected.to eq idx }
        its(:'a.to_a') { is_expected.to eq ['a', 'b', 'c'] }
      end
    end

    context DaruLite::MultiIndex do
      let (:idx) do
        DaruLite::MultiIndex.from_tuples [
          [:a,:one,:bar],
          [:a,:one,:baz],
          [:b,:two,:bar],
        ]
      end
      let(:df) do
        DaruLite::DataFrame.new({
          1 => 1..3,
          a: 'a'..'c',
          b: 11..13
        }, index: idx)
      end

      context "single position" do
        subject { df.at 1 }

        it { is_expected.to be_a DaruLite::Vector }
        its(:size) { is_expected.to eq 3 }
        its(:to_a) { is_expected.to eq ['a', 'b', 'c'] }
        its(:index) { is_expected.to eq idx }
      end

      context "multiple positions" do
        subject { df.at 0, 2 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:shape) { is_expected.to eq [3, 2] }
        its(:index) { is_expected.to eq idx }
        it { expect(df[1].to_a).to eq [1, 2, 3] }
        its(:'b.to_a') { is_expected.to eq [11, 12, 13] }
      end

      context "single invalid position" do
        it { expect { df. at 3 }.to raise_error IndexError }
      end

      context "multiple invalid positions" do
        it { expect { df.at 2, 3 }.to raise_error IndexError }
      end

      context "range" do
        subject { df.at 0..1 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:shape) { is_expected.to eq [3, 2] }
        its(:index) { is_expected.to eq idx }
        it { expect(df[1].to_a).to eq [1, 2, 3] }
        its(:'a.to_a') { is_expected.to eq ['a', 'b', 'c'] }
      end

      context "range with negative end" do
        subject { df.at 0..-2 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:shape) { is_expected.to eq [3, 2] }
        its(:index) { is_expected.to eq idx }
        it { expect(df[1].to_a).to eq [1, 2, 3] }
        its(:'a.to_a') { is_expected.to eq ['a', 'b', 'c'] }
      end

      context "range with single element" do
        subject { df.at 1..1 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:shape) { is_expected.to eq [3, 1] }
        its(:index) { is_expected.to eq idx }
        its(:'a.to_a') { is_expected.to eq ['a', 'b', 'c'] }
      end
    end

    context DaruLite::CategoricalIndex do
      let (:idx) { DaruLite::CategoricalIndex.new [:a, 1, 1] }
      let(:df) do
        DaruLite::DataFrame.new({
          1 => 1..3,
          a: 'a'..'c',
          b: 11..13
        }, index: idx)
      end

      context "single position" do
        subject { df.at 1 }

        it { is_expected.to be_a DaruLite::Vector }
        its(:size) { is_expected.to eq 3 }
        its(:to_a) { is_expected.to eq ['a', 'b', 'c'] }
        its(:index) { is_expected.to eq idx }
      end

      context "multiple positions" do
        subject { df.at 0, 2 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:shape) { is_expected.to eq [3, 2] }
        its(:index) { is_expected.to eq idx }
        it { expect(df[1].to_a).to eq [1, 2, 3] }
        its(:'b.to_a') { is_expected.to eq [11, 12, 13] }
      end

      context "single invalid position" do
        it { expect { df. at 3 }.to raise_error IndexError }
      end

      context "multiple invalid positions" do
        it { expect { df.at 2, 3 }.to raise_error IndexError }
      end

      context "range" do
        subject { df.at 0..1 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:shape) { is_expected.to eq [3, 2] }
        its(:index) { is_expected.to eq idx }
        it { expect(df[1].to_a).to eq [1, 2, 3] }
        its(:'a.to_a') { is_expected.to eq ['a', 'b', 'c'] }
      end

      context "range with negative index" do
        subject { df.at 0..-2 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:shape) { is_expected.to eq [3, 2] }
        its(:index) { is_expected.to eq idx }
        it { expect(df[1].to_a).to eq [1, 2, 3] }
        its(:'a.to_a') { is_expected.to eq ['a', 'b', 'c'] }
      end

      context "range with single element" do
        subject { df.at 1..1 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:shape) { is_expected.to eq [3, 1] }
        its(:index) { is_expected.to eq idx }
        its(:'a.to_a') { is_expected.to eq ['a', 'b', 'c'] }
      end
    end
  end

  context "#first" do
    it 'works' do
      expect(df.first(2)).to eq(
        DaruLite::DataFrame.new({b: [11,12], a: [1,2], c: [11,22]},
        order: [:a, :b, :c],
        index: [:one, :two]))
    end

    it 'works with too large values' do
      expect(df.first(200)).to eq(df)
    end

    it 'has synonym' do
      expect(df.first(2)).to eq(df.head(2))
    end

    it 'works on DateTime indexes' do
      idx = DaruLite::DateTimeIndex.new(['2017-01-01', '2017-02-01', '2017-03-01'])
      df = DaruLite::DataFrame.new({col1: ['a', 'b', 'c']}, index: idx)
      first = DaruLite::DataFrame.new({col1: ['a']}, index: DaruLite::DateTimeIndex.new(['2017-01-01']))
      expect(df.head(1)).to eq(first)
    end
  end

  context "#last" do
    it 'works' do
      expect(df.last(2)).to eq(
        DaruLite::DataFrame.new({b: [14,15], a: [4,5], c: [44,55]},
        order: [:a, :b, :c],
        index: [:four, :five]))
    end

    it 'works with too large values' do
      expect(df.last(200)).to eq(df)
    end

    it 'has synonym' do
      expect(df.last(2)).to eq(df.tail(2))
    end
  end

  context '#access_row_tuples_by_indexs' do
    let(:df) {
      DaruLite::DataFrame.new({col: [:a, :b, :c, :d, :e], num: [52,12,07,17,01]}) }
    let(:df_idx) {
      DaruLite::DataFrame.new({a: [52, 12, 07], b: [1, 2, 3]}, index: [:one, :two, :three])
    }
    let (:mi_idx) do
      DaruLite::MultiIndex.from_tuples [
        [:a,:one,:bar],
        [:a,:one,:baz],
        [:b,:two,:bar],
        [:a,:two,:baz],
      ]
    end
    let (:df_mi) do
      DaruLite::DataFrame.new({
        a: 1..4,
        b: 'a'..'d'
      }, index: mi_idx )
    end
    context 'when no index is given' do
      it 'returns empty Array' do
        expect(df.access_row_tuples_by_indexs()).to eq([])
      end
    end
    context 'when index(s) are given' do
      it 'returns Array of row tuples' do
        expect(df.access_row_tuples_by_indexs(1)).to eq([[:b, 12]])
        expect(df.access_row_tuples_by_indexs(0,3)).to eq([[:a, 52], [:d, 17]])
      end
    end
    context 'when custom index(s) are given' do
      it 'returns Array of row tuples' do
        expect(df_idx.access_row_tuples_by_indexs(:one,:three)).to eq(
          [[52, 1], [7, 3]]
        )
      end
    end
    context 'when multi index is given' do
      it 'returns Array of row tuples' do
        expect(df_mi.access_row_tuples_by_indexs(:a)).to eq(
          [[1, "a"], [2, "b"], [4, "d"]]
        )
        expect(df_mi.access_row_tuples_by_indexs(:a, :one, :baz)).to eq(
          [[2, "b"]]
        )
      end
    end
  end

  context "#only_numerics" do
    subject { df.only_numerics }

    let(:df) do
      DaruLite::DataFrame.new({a: vector1, b: vector2, c: vector3 }, clone: false)
    end
    let(:vector1) { DaruLite::Vector.new([1,2,3,4,5]) }
    let(:vector2) { DaruLite::Vector.new(%w(one two three four five)) }
    let(:vector3) { DaruLite::Vector.new([11,22,33,44,55]) }

    it "returns a clone of numeric vectors" do
      expect(subject).to eq(
        DaruLite::DataFrame.new({ a: vector1, c: vector3}, clone: false)
      )
      expect(subject[:a].object_id).to_not eq(vector1.object_id)
    end

    context 'clone is false' do
      subject { df.only_numerics(clone: false) }

      it "returns a view of only the numeric vectors" do
        expect(subject).to eq(
          DaruLite::DataFrame.new({ a: vector1, c: vector3 }, clone: false)
        )
        expect(subject[:a].object_id).to eq(vector1.object_id)
      end
    end

    context DaruLite::MultiIndex do
      let(:df) do
        order = DaruLite::MultiIndex.from_tuples(
          [
            [:d, :one, :large],
            [:d, :one, :small],
            [:d, :two, :large],
            [:d, :two, :small],
            [:e, :one, :large],
            [:e, :one, :small],
            [:e, :two, :large],
            [:e, :two, :small]
          ]
        )

        index = DaruLite::MultiIndex.from_tuples(
          [
            [:bar],
            [:foo]
          ]
        )
        DaruLite::DataFrame.new(
          [
            [4.112,2.234],
            %w(a b),
            [6.342,nil],
            [7.2344,3.23214],
            [8.234,4.533],
            [10.342,2.3432],
            [12.0,nil],
            %w(a b)
          ],
          order:,
          index:
        )
      end

      it "returns numeric vectors" do
        vectors = DaruLite::MultiIndex.from_tuples(
          [
            [:d, :one, :large],
            [:d, :two, :large],
            [:d, :two, :small],
            [:e, :one, :large],
            [:e, :one, :small],
            [:e, :two, :large]
          ]
        )
        index = DaruLite::MultiIndex.from_tuples(
          [
            [:bar],
            [:foo]
          ]
        )
        answer = DaruLite::DataFrame.new(
          [
            [4.112,2.234],
            [6.342,nil],
            [7.2344,3.23214],
            [8.234,4.533],
            [10.342,2.3432],
            [12.0,nil],
          ], order: vectors, index: index
        )

        expect(subject).to eq(answer)
      end
    end
  end
end
