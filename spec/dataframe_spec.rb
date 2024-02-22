require 'data_frame/aggregatable_example'
require 'data_frame/buildable_example'
require 'data_frame/calculatable_example'
require 'data_frame/convertible_example'
require 'data_frame/duplicatable_example'
require 'data_frame/fetchable_example'
require 'data_frame/filterable_example'
require 'data_frame/indexable_example'
require 'data_frame/iterable_example'
require 'data_frame/joinable_example'
require 'data_frame/missable_example'
require 'data_frame/pivotable_example'
require 'data_frame/queryable_example'
require 'data_frame/setable_example'
require 'data_frame/sortable_example'

describe DaruLite::DataFrame do
  let(:df) do
    DaruLite::DataFrame.new(
      { b: [11,12,13,14,15], a: [1,2,3,4,5], c: [11,22,33,44,55] },
      order: [:a, :b, :c],
      index: [:one, :two, :three, :four, :five]
    )
  end
  let(:df_mi) do
    DaruLite::DataFrame.new(
      [vector_arry1, vector_arry2, vector_arry1, vector_arry2],
      order: order_mi,
      index: multi_index
    )
  end
  let(:vector_arry1) { [11,12,13,14,11,12,13,14,11,12,13,14] }
  let(:vector_arry2) { [1,2,3,4,1,2,3,4,1,2,3,4] }
  let(:multi_index) do
    tuples = [
      [:a,:one,:bar],
      [:a,:one,:baz],
      [:a,:two,:bar],
      [:a,:two,:baz],
      [:b,:one,:bar],
      [:b,:two,:bar],
      [:b,:two,:baz],
      [:b,:one,:foo],
      [:c,:one,:bar],
      [:c,:one,:baz],
      [:c,:two,:foo],
      [:c,:two,:bar]
    ]
    DaruLite::MultiIndex.from_tuples(tuples)
  end
  let(:order_mi) do
    DaruLite::MultiIndex.from_tuples(
      [
        [:a,:one,:bar],
        [:a,:two,:baz],
        [:b,:two,:foo],
        [:b,:one,:foo]
      ]
    )
  end

  it_behaves_like 'an aggregatable DataFrame'
  it_behaves_like 'a buildable DataFrame'
  it_behaves_like 'a calculatable DataFrame'
  it_behaves_like 'a convertible DataFrame'
  it_behaves_like 'a duplicatable DataFrame'
  it_behaves_like 'a fetchable DataFrame'
  it_behaves_like 'a filterable DataFrame'
  it_behaves_like 'an indexable DataFrame'
  it_behaves_like 'an iterable DataFrame'
  it_behaves_like 'a joinable DataFrame'
  it_behaves_like 'a missable DataFrame'
  it_behaves_like 'a pivotable DataFrame'
  it_behaves_like 'a queryable DataFrame'
  it_behaves_like 'a setable DataFrame'
  it_behaves_like 'a sortable DataFrame'

  context "#initialize" do
    it "initializes an empty DataFrame with no arguments" do
      df = DaruLite::DataFrame.new
      expect(df.nrows).to eq(0)
      expect(df.ncols).to eq(0)
    end

    context DaruLite::Index do
      it "initializes an empty DataFrame with empty source arg" do
        df = DaruLite::DataFrame.new({}, order: [:a, :b])

        expect(df.vectors).to eq(DaruLite::Index.new [:a, :b])
        expect(df.a.class).to eq(DaruLite::Vector)
        expect(df.a)      .to eq([].dv(:a))
      end

      it "initializes from a Hash" do
        df = DaruLite::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]}, order: [:a, :b],
          index: [:one, :two, :three, :four, :five])

        expect(df.index)  .to eq(DaruLite::Index.new [:one, :two, :three, :four, :five])
        expect(df.vectors).to eq(DaruLite::Index.new [:a, :b])
        expect(df.a.class).to eq(DaruLite::Vector)
        expect(df.a)      .to eq([1,2,3,4,5].dv(:a, df.index))
      end

      it "initializes from a Hash and preserves default order" do
        df = DaruLite::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]},
          index: [:one, :two, :three, :four, :five])

        expect(df.vectors).to eq(DaruLite::Index.new [:b, :a])
      end

      it "initializes from a Hash of Vectors" do
        va = DaruLite::Vector.new([1,2,3,4,5], index: [:one, :two, :three, :four, :five])
        vb = DaruLite::Vector.new([11,12,13,14,15], index: [:one, :two, :three, :four, :five])

        df = DaruLite::DataFrame.new({ b: vb, a: va }, order: [:a, :b], index: [:one, :two, :three, :four, :five])

        expect(df.index)  .to eq(DaruLite::Index.new [:one, :two, :three, :four, :five])
        expect(df.vectors).to eq(DaruLite::Index.new [:a, :b])
        expect(df.a.class).to eq(DaruLite::Vector)
        expect(df.a)      .to eq([1,2,3,4,5].dv(:a, [:one, :two, :three, :four, :five]))
      end

      it "initializes from an Array of Hashes" do
        df = DaruLite::DataFrame.new([{a: 1, b: 11}, {a: false, b: 12}, {a: 3, b: 13},
          {a: 4, b: 14}, {a: 5, b: 15}], order: [:b, :a],
          index: [:one, :two, :three, :four, :five])

        expect(df.index)  .to eq(DaruLite::Index.new [:one, :two, :three, :four, :five])
        expect(df.vectors).to eq(DaruLite::Index.new [:b, :a])
        expect(df.a.class).to eq(DaruLite::Vector)
        expect(df.a)      .to eq([1,false,3,4,5].dv(:a,[:one, :two, :three, :four, :five]))
      end

      it "initializes from Array of Arrays" do
        df = DaruLite::DataFrame.new([[1]*5, [2]*5, [3]*5], order: [:b, :a, :c])

        expect(df.index)  .to eq(DaruLite::Index.new(5))
        expect(df.vectors).to eq(DaruLite::Index.new([:b, :a, :c]))
        expect(df.a)      .to eq(DaruLite::Vector.new([2]*5))
      end

      it "initializes from Array of Vectors" do
        df = DaruLite::DataFrame.new([DaruLite::Vector.new([1]*5), DaruLite::Vector.new([2]*5),
         DaruLite::Vector.new([3]*5)], order: [:b, :a, :c])

        expect(df.index)  .to eq(DaruLite::Index.new(5))
        expect(df.vectors).to eq(DaruLite::Index.new([:b, :a, :c]))
        expect(df.a)      .to eq(DaruLite::Vector.new([2]*5))
      end

      it "accepts Index objects for row/col" do
        rows = DaruLite::Index.new [:one, :two, :three, :four, :five]
        cols = DaruLite::Index.new [:a, :b]

        df  = DaruLite::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]}, order: cols,
          index: rows)

        expect(df.a)      .to eq(DaruLite::Vector.new([1,2,3,4,5], order: [:a], index: rows))
        expect(df.b)      .to eq(DaruLite::Vector.new([11,12,13,14,15], name: :b, index: rows))
        expect(df.index)  .to eq(DaruLite::Index.new [:one, :two, :three, :four, :five])
        expect(df.vectors).to eq(DaruLite::Index.new [:a, :b])
      end

      it "initializes without specifying row/col index" do
        df = DaruLite::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]})

        expect(df.index)  .to eq(DaruLite::Index.new [0,1,2,3,4])
        expect(df.vectors).to eq(DaruLite::Index.new [:b, :a])
      end

      it "aligns indexes properly" do
        df = DaruLite::DataFrame.new({
            b: [11,12,13,14,15].dv(:b, [:two, :one, :four, :five, :three]),
            a:      [1,2,3,4,5].dv(:a, [:two,:one,:three, :four, :five])
          },
            order: [:a, :b]
          )

        expect(df).to eq(DaruLite::DataFrame.new({
            b: [14,13,12,15,11].dv(:b, [:five, :four, :one, :three, :two]),
            a:      [5,4,2,3,1].dv(:a, [:five, :four, :one, :three, :two])
          }, order: [:a, :b])
        )
      end

      it "adds nil values for missing indexes and aligns by index" do
        df = DaruLite::DataFrame.new({
                 b: [11,12,13,14,15].dv(:b, [:two, :one, :four, :five, :three]),
                 a: [1,2,3]         .dv(:a, [:two,:one,:three])
               },
               order: [:a, :b]
             )

        expect(df).to eq(DaruLite::DataFrame.new({
            b: [14,13,12,15,11].dv(:b, [:five, :four, :one, :three, :two]),
            a:  [nil,nil,2,3,1].dv(:a, [:five, :four, :one, :three, :two])
          },
          order: [:a, :b])
        )
      end

      it "adds nils in first vector when other vectors have many extra indexes" do
        df = DaruLite::DataFrame.new({
            b: [11]                .dv(nil, [:one]),
            a: [1,2,3]             .dv(nil, [:one, :two, :three]),
            c: [11,22,33,44,55]    .dv(nil, [:one, :two, :three, :four, :five]),
            d: [49,69,89,99,108,44].dv(nil, [:one, :two, :three, :four, :five, :six])
          }, order: [:a, :b, :c, :d],
          index: [:one, :two, :three, :four, :five, :six])

        expect(df).to eq(DaruLite::DataFrame.new({
            b: [11,nil,nil,nil,nil,nil].dv(nil, [:one, :two, :three, :four, :five, :six]),
            a: [1,2,3,nil,nil,nil]     .dv(nil, [:one, :two, :three, :four, :five, :six]),
            c: [11,22,33,44,55,nil]    .dv(nil, [:one, :two, :three, :four, :five, :six]),
            d: [49,69,89,99,108,44]    .dv(nil, [:one, :two, :three, :four, :five, :six])
          }, order: [:a, :b, :c, :d],
          index: [:one, :two, :three, :four, :five, :six])
        )
      end

      it "correctly matches the supplied DataFrame index with the individual vector indexes" do
        df = DaruLite::DataFrame.new({
            b: [11,12,13] .dv(nil, [:one, :bleh, :blah]),
            a: [1,2,3,4,5].dv(nil, [:one, :two, :booh, :baah, :three]),
            c: [11,22,33,44,55].dv(nil, [0,1,3,:three, :two])
          }, order: [:a, :b, :c], index: [:one, :two, :three])

        expect(df).to eq(DaruLite::DataFrame.new({
            b: [11,nil,nil].dv(nil, [:one, :two, :three]),
            a: [1,2,5]     .dv(nil, [:one, :two, :three]),
            c: [nil,55,44] .dv(nil, [:one, :two, :three]),
          },
          order: [:a, :b, :c], index: [:one, :two, :three]
          )
        )
      end

      it "completes incomplete vectors" do
        df = DaruLite::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
          c: [11,22,33,44,55]}, order: [:a, :c])

        expect(df.vectors).to eq([:a,:c,:b].to_index)
      end

      it "does not copy vectors when clone: false" do
        a = DaruLite::Vector.new([1,2,3,4,5])
        b = DaruLite::Vector.new([1,2,3,4,5])
        c = DaruLite::Vector.new([1,2,3,4,5])
        df = DaruLite::DataFrame.new({a: a, b: b, c: c}, clone: false)

        expect(df[:a].object_id).to eq(a.object_id)
        expect(df[:b].object_id).to eq(b.object_id)
        expect(df[:c].object_id).to eq(c.object_id)
      end

      it "allows creation of empty dataframe with only order" do
        df = DaruLite::DataFrame.new({}, order: [:a, :b, :c])
        df[:a] = DaruLite::Vector.new([1,2,3,4,5,6])

        expect(df.size).to eq(6)
        expect(df[:a]).to eq(DaruLite::Vector.new([1,2,3,4,5,6]))
        expect(df[:b]).to eq(DaruLite::Vector.new([nil,nil,nil,nil,nil,nil]))
        expect(df[:c]).to eq(DaruLite::Vector.new([nil,nil,nil,nil,nil,nil]))
      end

      it "allows creation of dataframe without specifying order or index" do
        df = DaruLite::DataFrame.new({})
        df[:a] = DaruLite::Vector.new([1,2,3,4,5])

        expect(df.size)        .to eq(5)
        expect(df.index.to_a)  .to eq([0,1,2,3,4])
        expect(df.vectors.to_a).to eq([:a])
        expect(df[:a])         .to eq(DaruLite::Vector.new([1,2,3,4,5]))
      end

      it "allows creation of dataframe with a default order" do
        arr_of_arrs_df    = DaruLite::DataFrame.new([[1,2,3], [4,5,6], [7,8,9]])
        arr_of_vectors_df = DaruLite::DataFrame.new([DaruLite::Vector.new([1,2,3]), DaruLite::Vector.new([4,5,6]), DaruLite::Vector.new([7,8,9])])

        expect(arr_of_arrs_df.vectors.to_a).to eq([0,1,2])
        expect(arr_of_vectors_df.vectors.to_a).to eq([0,1,2])
      end

      it "raises error for incomplete DataFrame index" do
        expect {
          df = DaruLite::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
            c: [11,22,33,44,55]}, order: [:a, :b, :c],
            index: [:one, :two, :three])
        }.to raise_error
      end

      it "raises error for unequal sized vectors/arrays" do
        expect {
          df = DaruLite::DataFrame.new({b: [11,12,13], a: [1,2,3,4,5],
            c: [11,22,33,44,55]}, order: [:a, :b, :c],
            index: [:one, :two, :three])
        }.to raise_error
      end
    end

    context DaruLite::MultiIndex do
      it "creates empty DataFrame" do
        df = DaruLite::DataFrame.new({}, order: order_mi)

        expect(df.vectors).to eq(order_mi)
        expect(df[:a, :one, :bar]).to eq(DaruLite::Vector.new([]))
      end

      it "creates from Hash" do
        df = DaruLite::DataFrame.new({
          [:a,:one,:bar] => vector_arry1,
          [:a,:two,:baz] => vector_arry2,
          [:b,:one,:foo] => vector_arry1,
          [:b,:two,:foo] => vector_arry2
          }, order: order_mi, index: multi_index)

        expect(df.index)               .to eq(multi_index)
        expect(df.vectors)             .to eq(order_mi)
        expect(df[:a,:one,:bar]).to eq(DaruLite::Vector.new(vector_arry1,
          index: multi_index))
      end

      it "creates from Array of Hashes" do
        # TODO
      end

      it "creates from Array of Arrays" do
        df = DaruLite::DataFrame.new([vector_arry1, vector_arry2, vector_arry1,
          vector_arry2], index: multi_index, order: order_mi)

        expect(df.index)  .to eq(multi_index)
        expect(df.vectors).to eq(order_mi)
        expect(df[:a, :one, :bar]).to eq(DaruLite::Vector.new(vector_arry1,
          index: multi_index))
      end

      it "raises error for order MultiIndex of different size than supplied Array" do
        expect {
          df = DaruLite::DataFrame.new([vector_arry1, vector_arry2], order: order_mi,
            index: multi_index)
        }.to raise_error
      end

      it "aligns MultiIndexes properly" do
        pending
        mi_a = order_mi
        mi_b = DaruLite::MultiIndex.from_tuples([
          [:b,:one,:foo],
          [:a,:one,:bar],
          [:b,:two,:foo],
          [:a,:one,:baz]
        ])
        mi_sorted = DaruLite::MultiIndex.from_tuples([
          [:a, :one, :bar],
          [:a, :one, :baz],
          [:b, :one, :foo],
          [:b, :two, :foo]
        ])
        order = DaruLite::MultiIndex.from_tuples([
          [:pee, :que],
          [:pee, :poo]
        ])
        a  = DaruLite::Vector.new([1,2,3,4], index: mi_a)
        b  = DaruLite::Vector.new([11,12,13,14], index: mi_b)
        df = DaruLite::DataFrame.new([b,a], order: order)

        expect(df).to eq(DaruLite::DataFrame.new({
          [:pee, :que] => DaruLite::Vector.new([1,2,4,3], index: mi_sorted),
          [:pee, :poo] => DaruLite::Vector.new([12,14,11,13], index: mi_sorted)
          }, order: order_mi))
      end

      it "adds nils in case of missing values" do
        # TODO
      end

      it "matches individual vector indexing with supplied DataFrame index" do
        # TODO
      end
    end
  end

  context '#method_missing' do
    let(:df) { DaruLite::DataFrame.new({
      :a  => [1, 2, 3, 4, 5],
      'b' => [5, 4, 3, 2, 1]
    }, index: 11..15)}

    context 'get vector' do
      context 'by string' do
        subject { df.b }

        it { is_expected.to be_a DaruLite::Vector }
        its(:to_a) { is_expected.to eq [5, 4, 3, 2, 1] }
        its(:'index.to_a') { is_expected.to eq [11, 12, 13, 14, 15] }
      end

      context 'by symbol' do
        subject { df.a }

        it { is_expected.to be_a DaruLite::Vector }
        its(:to_a) { is_expected.to eq [1, 2, 3, 4, 5] }
        its(:'index.to_a') { is_expected.to eq [11, 12, 13, 14, 15] }
      end
    end

    context 'set existing vector' do
      context 'by string' do
        before { df.b = [:a, :b, :c, :d, :e] }
        subject { df }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:'vectors.to_a') { is_expected.to eq [:a, 'b'] }
        its(:'b.to_a') { is_expected.to eq [:a, :b, :c, :d, :e] }
        its(:'index.to_a') { is_expected.to eq [11, 12, 13, 14, 15] }
      end

      context 'by symbol' do
        before { df.a = [:a, :b, :c, :d, :e] }
        subject { df }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:'vectors.to_a') { is_expected.to eq [:a, 'b'] }
        its(:'a.to_a') { is_expected.to eq [:a, :b, :c, :d, :e] }
        its(:'index.to_a') { is_expected.to eq [11, 12, 13, 14, 15] }
      end
    end

    context 'set new vector' do
      before { df.c = [5, 5, 5, 5, 5] }
      subject { df }

      it { is_expected.to be_a DaruLite::DataFrame }
      its(:'vectors.to_a') { is_expected.to eq [:a, 'b', :c] }
      its(:'c.to_a') { is_expected.to eq [5, 5, 5, 5, 5] }
      its(:'index.to_a') { is_expected.to eq [11, 12, 13, 14, 15] }
    end

    context 'reference invalid vector' do
      it { expect { df.d }.to raise_error NoMethodError }
    end
  end

  context "#row.at" do
    context DaruLite::Index do
      let(:idx) { DaruLite::Index.new [1, 0, :c] }
      let(:df) do
        DaruLite::DataFrame.new({
          a: 1..3,
          b: 'a'..'c'
        }, index: idx)
      end

      context "single position" do
        subject { df.row.at 1 }

        it { is_expected.to be_a DaruLite::Vector }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq [2, 'b'] }
        its(:'index.to_a') { is_expected.to eq [:a, :b] }
      end

      context "multiple positions" do
        subject { df.row.at 0, 2 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:size) { is_expected.to eq 2 }
        its(:'index.to_a') { is_expected.to eq [1, :c] }
        its(:'a.to_a') { is_expected.to eq [1, 3] }
        its(:'b.to_a') { is_expected.to eq ['a', 'c'] }
      end

      context "invalid position" do
        it { expect { df.row.at 3 }.to raise_error IndexError }
      end

      context "invalid positions" do
        it { expect { df.row.at 2, 3 }.to raise_error IndexError }
      end

      context "range" do
        subject { df.row.at 0..1 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:size) { is_expected.to eq 2 }
        its(:'index.to_a') { is_expected.to eq [1, 0] }
        its(:'a.to_a') { is_expected.to eq [1, 2] }
        its(:'b.to_a') { is_expected.to eq ['a', 'b'] }
      end

      context "range with negative end" do
        subject { df.row.at 0..-2 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:size) { is_expected.to eq 2 }
        its(:'index.to_a') { is_expected.to eq [1, 0] }
        its(:'a.to_a') { is_expected.to eq [1, 2] }
        its(:'b.to_a') { is_expected.to eq ['a', 'b'] }
      end

      context "range with single element" do
        subject { df.row.at 0..0 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:size) { is_expected.to eq 1 }
        its(:'index.to_a') { is_expected.to eq [1] }
        its(:'a.to_a') { is_expected.to eq [1] }
        its(:'b.to_a') { is_expected.to eq ['a'] }
      end
    end

    context DaruLite::MultiIndex do
      let (:idx) do
        DaruLite::MultiIndex.from_tuples [
          [:a,:one,:bar],
          [:a,:one,:baz],
          [:b,:two,:bar],
          [:a,:two,:baz],
        ]
      end
      let (:df) do
        DaruLite::DataFrame.new({
          a: 1..4,
          b: 'a'..'d'
        }, index: idx )
      end

      context "single position" do
        subject { df.row.at 1 }

        it { is_expected.to be_a DaruLite::Vector }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq [2, 'b'] }
        its(:'index.to_a') { is_expected.to eq [:a, :b] }
      end

      context "multiple positions" do
        subject { df.row.at 0, 2 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:size) { is_expected.to eq 2 }
        its(:'index.to_a') { is_expected.to eq [[:a, :one, :bar],
          [:b, :two, :bar]] }
        its(:'a.to_a') { is_expected.to eq [1, 3] }
        its(:'a.index.to_a') { is_expected.to eq [[:a, :one, :bar],
          [:b, :two, :bar]] }
        its(:'b.to_a') { is_expected.to eq ['a', 'c'] }
      end

      context "invalid position" do
        it { expect { df.row.at 4 }.to raise_error IndexError }
      end

      context "invalid positions" do
        it { expect { df.row.at 3, 4 }.to raise_error IndexError }
      end

      context "range" do
        subject { df.row.at 0..1 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:size) { is_expected.to eq 2 }
        its(:'index.to_a') { is_expected.to eq [[:a, :one, :bar],
          [:a, :one, :baz]] }
        its(:'a.to_a') { is_expected.to eq [1, 2] }
        its(:'a.index.to_a') { is_expected.to eq [[:a, :one, :bar],
          [:a, :one, :baz]] }
        its(:'b.to_a') { is_expected.to eq ['a', 'b'] }
      end

      context "range with negative end" do
        subject { df.row.at 0..-3 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:size) { is_expected.to eq 2 }
        its(:'index.to_a') { is_expected.to eq [[:a, :one, :bar],
          [:a, :one, :baz]] }
        its(:'a.to_a') { is_expected.to eq [1, 2] }
        its(:'a.index.to_a') { is_expected.to eq [[:a, :one, :bar],
          [:a, :one, :baz]] }
        its(:'b.to_a') { is_expected.to eq ['a', 'b'] }
      end

      context " range with single element" do
        subject { df.row.at 0..0 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:size) { is_expected.to eq 1 }
        its(:'index.to_a') { is_expected.to eq [[:a, :one, :bar]] }
        its(:'a.to_a') { is_expected.to eq [1] }
        its(:'a.index.to_a') { is_expected.to eq [[:a, :one, :bar]] }
        its(:'b.to_a') { is_expected.to eq ['a'] }
      end
    end

    context DaruLite::CategoricalIndex do
      let (:idx) { DaruLite::CategoricalIndex.new [:a, 1, 1, :a, :c] }
      let (:df)  do
        DaruLite::DataFrame.new({
          a: 1..5,
          b: 'a'..'e'
        }, index: idx )
      end

      context "single positional index" do
        subject { df.row.at 1 }

        it { is_expected.to be_a DaruLite::Vector }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq [2, 'b'] }
        its(:'index.to_a') { is_expected.to eq [:a, :b] }
      end

      context "multiple positional indexes" do
        subject { df.row.at 0, 2 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:size) { is_expected.to eq 2 }
        its(:'index.to_a') { is_expected.to eq [:a, 1] }
        its(:'a.to_a') { is_expected.to eq [1, 3] }
        its(:'a.index.to_a') { is_expected.to eq [:a, 1] }
        its(:'b.to_a') { is_expected.to eq ['a', 'c'] }
        its(:'b.index.to_a') { is_expected.to eq [:a, 1] }
      end

      context "invalid position" do
        it { expect { df.at 5 }.to raise_error IndexError }
      end

      context "invalid positions" do
        it { expect { df.at 4, 5 }.to raise_error IndexError }
      end

      context "range" do
        subject { df.row.at 0..1 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:size) { is_expected.to eq 2 }
        its(:'index.to_a') { is_expected.to eq [:a, 1] }
        its(:'a.to_a') { is_expected.to eq [1, 2] }
        its(:'a.index.to_a') { is_expected.to eq [:a, 1] }
        its(:'b.to_a') { is_expected.to eq ['a', 'b'] }
        its(:'b.index.to_a') { is_expected.to eq [:a, 1] }
      end

      context "range with negative end" do
        subject { df.row.at 0..-4 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:size) { is_expected.to eq 2 }
        its(:'index.to_a') { is_expected.to eq [:a, 1] }
        its(:'a.to_a') { is_expected.to eq [1, 2] }
        its(:'a.index.to_a') { is_expected.to eq [:a, 1] }
        its(:'b.to_a') { is_expected.to eq ['a', 'b'] }
        its(:'b.index.to_a') { is_expected.to eq [:a, 1] }
      end

      context " range with single element" do
        subject { df.row.at 0..0 }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:size) { is_expected.to eq 1 }
        its(:'index.to_a') { is_expected.to eq [:a] }
        its(:'a.to_a') { is_expected.to eq [1] }
        its(:'a.index.to_a') { is_expected.to eq [:a] }
        its(:'b.to_a') { is_expected.to eq ['a'] }
        its(:'b.index.to_a') { is_expected.to eq [:a] }
      end
    end
  end

  context "#row[]" do
    context DaruLite::Index do
      before :each do
        @df = DaruLite::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
          c: [11,22,33,44,55]}, order: [:a, :b, :c],
          index: [:one, :two, :three, :four, :five])
      end

      it "creates an index for assignment if not already specified" do
        @df.row[:one] = [49, 99, 59]

        expect(@df[:one, :row])      .to eq([49, 99, 59].dv(:one, [:a, :b, :c]))
        expect(@df[:one, :row].index).to eq([:a, :b, :c].to_index)
        expect(@df[:one, :row].name) .to eq(:one)
      end

      it "returns a DataFrame when specifying numeric Range" do
        expect(@df.row[0..2]).to eq(
          DaruLite::DataFrame.new({b: [11,12,13], a: [1,2,3],
            c: [11,22,33]}, order: [:a, :b, :c],
            index: [:one, :two, :three])
          )
      end

      it "returns a DataFrame when specifying symbolic Range" do
        expect(@df.row[:one..:three]).to eq(
          DaruLite::DataFrame.new({b: [11,12,13], a: [1,2,3],
            c: [11,22,33]}, order: [:a, :b, :c],
            index: [:one, :two, :three])
          )
      end

      it "returns a row with the given index" do
        expect(@df.row[:one]).to eq([1,11,11].dv(:one, [:a, :b, :c]))
      end

      it "returns a row with given Integer index" do
        expect(@df.row[0]).to eq([1,11,11].dv(:one, [:a, :b, :c]))
      end

      it "returns a row with given Integer index for default index-less DataFrame" do
        df = DaruLite::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
          c: [11,22,33,44,55]}, order: [:a, :b, :c])

        expect(df.row[0]).to eq([1,11,11].dv(nil, [:a, :b, :c]))
        expect(df.row[3]).to eq([4,14,44].dv(nil, [:a, :b, :c]))
      end

      it "returns a row with given Integer index for numerical index DataFrame" do
        df = DaruLite::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
          c: [11,22,33,44,55]}, order: [:a, :b, :c], index: [1,2,3,4,5])

        expect(df.row[0]).to eq([1,11,11].dv(nil, [:a, :b, :c]))
        expect(df.row[3]).to eq([3,13,33].dv(nil, [:a, :b, :c]))
      end
    end

    context DaruLite::MultiIndex do
      it "returns a Vector when specifying integer index" do
        expect(df_mi.row[0]).to eq(DaruLite::Vector.new([11,1,11,1], index: order_mi))
      end

      it "returns a DataFrame whecn specifying numeric range" do
        sub_index = DaruLite::MultiIndex.from_tuples([
          [:a,:one,:bar],
          [:a,:one,:baz]
        ])

        expect(df_mi.row[0..1]).to eq(DaruLite::DataFrame.new([
          [11,12],
          [1,2],
          [11,12],
          [1,2]
        ], order: order_mi, index: sub_index, name: :numeric_range))
      end

      it "returns a Vector when specifying complete tuple" do
        expect(df_mi.row[:c,:two,:foo]).to eq(DaruLite::Vector.new([13,3,13,3], index: order_mi))
      end

      it "returns DataFrame when specifying first layer of MultiIndex" do
        sub_index = DaruLite::MultiIndex.from_tuples([
          [:one,:bar],
          [:one,:baz],
          [:two,:foo],
          [:two,:bar]
        ])
        expect(df_mi.row[:c]).to eq(DaruLite::DataFrame.new([
          [11,12,13,14],
          [1,2,3,4],
          [11,12,13,14],
          [1,2,3,4]
          ], index: sub_index, order: order_mi))
      end

      it "returns DataFrame when specifying first and second layer of MultiIndex" do
        sub_index = DaruLite::MultiIndex.from_tuples([
          [:bar],
          [:baz]
        ])
        expect(df_mi.row[:c,:one]).to eq(DaruLite::DataFrame.new([
          [11,12],
          [1,2],
          [11,12],
          [1,2]
        ], index: sub_index, order: order_mi))
      end
    end

    context DaruLite::CategoricalIndex do
      let(:idx) { DaruLite::CategoricalIndex.new [:a, 1, :a, 1, :c] }
      let(:df) do
        DaruLite::DataFrame.new({
          a: 'a'..'e',
          b: 1..5
        }, index: idx)
      end

      context "single category" do
        context "multiple instances" do
          subject { df.row[:a] }

          it { is_expected.to be_a DaruLite::DataFrame }
          its(:index) { is_expected.to eq DaruLite::CategoricalIndex.new [:a, :a] }
          its(:vectors) { is_expected.to eq DaruLite::Index.new [:a, :b] }
          its(:a) { DaruLite::Vector.new ['a', 'c'] }
          its(:b) { DaruLite::Vector.new [1, 3] }
        end

        context "single instance" do
          subject { df.row[:c] }

          it { is_expected.to be_a DaruLite::Vector }
          its(:index) { is_expected.to eq DaruLite::Index.new [:a, :b] }
          its(:to_a) { is_expected.to eq ['e', 5] }
        end
      end

      context "multiple categories" do
        subject { df.row[:a, 1] }

        it { is_expected.to be_a DaruLite::DataFrame }
        its(:index) { is_expected.to eq DaruLite::CategoricalIndex.new(
          [:a, 1, :a, 1 ]) }
        its(:vectors) { is_expected.to eq DaruLite::Index.new [:a, :b] }
        its(:a) { DaruLite::Vector.new ['a', 'c', 'b', 'd'] }
        its(:b) { DaruLite::Vector.new [1, 3, 2, 4] }
      end

      context "positional index" do
        subject { df.row[0] }

        it { is_expected.to be_a DaruLite::Vector }
        its(:index) { is_expected.to eq DaruLite::Index.new [:a, :b] }
        its(:to_a) { is_expected.to eq ['a', 1] }
      end

      context "invalid positional index" do
        it { expect { df.row[5] }.to raise_error IndexError }
      end

      context "invalid category" do
        it { expect { df.row[:d] }.to raise_error IndexError }
      end
    end
  end

  context "#==" do
    it "compares by vectors, index and values of a DataFrame (ignores name)" do
      a = DaruLite::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]},
        order: [:a, :b], index: [:one, :two, :three, :four, :five])

      b = DaruLite::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]},
        order: [:a, :b], index: [:one, :two, :three, :four, :five])

      expect(a).to eq(b)
    end
  end

  context '#rename' do
    subject { df.rename 'other' }

    it { is_expected.to be_a DaruLite::DataFrame }
    its(:name) { is_expected.to eq 'other' }
  end

  context "#delete_vector" do
    context DaruLite::Index do
      it "deletes the specified vector" do
        df.delete_vector :a

        expect(df).to eq(DaruLite::DataFrame.new({b: [11,12,13,14,15],
                c: [11,22,33,44,55]}, order: [:b, :c],
                index: [:one, :two, :three, :four, :five]))
      end
    end
  end

  context "#delete_vectors" do
    context DaruLite::Index do
      it "deletes the specified vectors" do
        df.delete_vectors :a, :b

        expect(df).to eq(DaruLite::DataFrame.new({
                c: [11,22,33,44,55]}, order: [:c],
                index: [:one, :two, :three, :four, :five]))
      end
    end
  end

  context "#delete_row" do
    it "deletes the specified row" do
      df.delete_row :three

      expect(df).to eq(DaruLite::DataFrame.new({b: [11,12,14,15], a: [1,2,4,5],
      c: [11,22,44,55]}, order: [:a, :b, :c], index: [:one, :two, :four, :five]))
    end
  end

  context "#rename_vectors!" do
    before do
      @df = DaruLite::DataFrame.new({
        a: [1,2,3,4,5],
        b: [11,22,33,44,55],
        c: %w(a b c d e)
      })
    end

    it "returns self as modified dataframe" do
      expect(@df.rename_vectors!(:a => :alpha)).to eq(@df)
    end

    it "re-uses rename_vectors method" do
      name_map = { :a => :alpha, :c => :gamma }
      expect(@df).to receive(:rename_vectors).with(name_map)
      @df.rename_vectors! name_map
    end
  end

  context "#rename_vectors" do
    before do
      @df = DaruLite::DataFrame.new({
        a: [1,2,3,4,5],
        b: [11,22,33,44,55],
        c: %w(a b c d e)
      })
    end

    it "returns DaruLite::Index" do
      expect(@df.rename_vectors(:a => :alpha)).to be_kind_of(DaruLite::Index)
    end

    it "renames vectors using a hash map" do
      @df.rename_vectors :a => :alpha, :c => :gamma
      expect(@df.vectors.to_a).to eq([:alpha, :b, :gamma])
    end

    it "overwrites vectors if the new name already exists" do
      saved_vector = @df[:a].dup

      @df.rename_vectors :a => :b
      expect(@df.vectors.to_a).to eq([:b, :c])
      expect(@df[:b]).to eq saved_vector
    end

    it "makes no changes if the old and new names are the same" do
      saved_vector = @df[:a].dup

      @df.rename_vectors :a => :a
      expect(@df.vectors.to_a).to eq([:a, :b, :c])
      expect(@df[:a]).to eq saved_vector
    end
  end

  context "#add_level_to_vectors" do
    subject { df.add_level_to_vectors(top_level_label) }

    let(:df) do
      DaruLite::DataFrame.new({
        a: [1, 2, 3, 4, 5],
        b: [11, 22, 33, 44, 55],
        c: %w(a b c d e)
      })
    end
    let(:top_level_label) { :percentages }
    let(:expected_index) do
      DaruLite::MultiIndex.from_tuples([
        [:percentages, :a], [:percentages, :b],[:percentages, :c],
      ])
    end

    it 'returns expected Multi::Index' do
      expect(subject).to eq(expected_index)
    end

    it 'updates dataframe vectors to the expected Multi::Index' do
      expect { subject }.to change { df.vectors }.to(expected_index)
    end
  end

  context "#transpose" do
    context DaruLite::Index do
      it "transposes a DataFrame including row and column indexing" do
        expect(df.transpose).to eq(DaruLite::DataFrame.new({
          one: [1,11,11],
          two: [2,12,22],
          three: [3,13,33],
          four: [4,14,44],
          five: [5,15,55]
          }, index: [:a, :b, :c],
          order: [:one, :two, :three, :four, :five])
        )
      end
    end

    context DaruLite::MultiIndex do
      it "transposes a DataFrame including row and column indexing" do
        expect(df_mi.transpose).to eq(DaruLite::DataFrame.new([
          vector_arry1,
          vector_arry2,
          vector_arry1,
          vector_arry2].transpose, index: order_mi, order: multi_index))
      end
    end
  end

  context "#shape" do
    it "returns an array containing number of rows and columns" do
      expect(df.shape).to eq([5,3])
    end
  end

  context "#nest" do
    it "nests in a hash" do
      df = DaruLite::DataFrame.new({
        :a => DaruLite::Vector.new(%w(a a a b b b)),
        :b => DaruLite::Vector.new(%w(c c d d e e)),
        :c => DaruLite::Vector.new(%w(f g h i j k))
      })
      nest = df.nest :a, :b
      expect(nest['a']['c']).to eq([{ :c => 'f' }, { :c => 'g' }])
      expect(nest['a']['d']).to eq([{ :c => 'h' }])
      expect(nest['b']['e']).to eq([{ :c => 'j' }, { :c => 'k' }])
    end
  end

  context "#add_vectors_by_split_recode" do
    before do
      @ds = DaruLite::DataFrame.new({
        :id   => DaruLite::Vector.new([1, 2, 3, 4, 5]),
        :name => DaruLite::Vector.new(%w(Alex Claude Peter Franz George)),
        :age  => DaruLite::Vector.new([20, 23, 25, 27, 5]),
        :city => DaruLite::Vector.new(['New York', 'London', 'London', 'Paris', 'Tome']),
        :a1   => DaruLite::Vector.new(['a,b', 'b,c', 'a', nil, 'a,b,c']) },
        order: [:id, :name, :age, :city, :a1])
    end

    it "" do
      @ds.add_vectors_by_split_recode(:a1, '_')
      expect(@ds.vectors.to_a)    .to eq([:id, :name, :age, :city ,:a1, :a1_1, :a1_2, :a1_3])
      expect(@ds[:a1_1].to_a).to eq([1, 0, 1, nil, 1])
      expect(@ds[:a1_2].to_a).to eq([1, 1, 0, nil, 1])
      expect(@ds[:a1_3].to_a).to eq([0, 1, 0, nil, 1])
    end
  end

  context "#add_vectors_by_split" do
    before do
      @ds = DaruLite::DataFrame.new({
        :id   => DaruLite::Vector.new([1, 2, 3, 4, 5]),
        :name => DaruLite::Vector.new(%w(Alex Claude Peter Franz George)),
        :age  => DaruLite::Vector.new([20, 23, 25, 27, 5]),
        :city => DaruLite::Vector.new(['New York', 'London', 'London', 'Paris', 'Tome']),
        :a1   => DaruLite::Vector.new(['a,b', 'b,c', 'a', nil, 'a,b,c'])
        }, order: [:id, :name, :age, :city, :a1])
    end

    it "" do
      @ds.add_vectors_by_split(:a1, '_')
      expect(@ds.vectors.to_a).to eq([:id, :name, :age, :city, :a1, :a1_a, :a1_b, :a1_c])
      expect(@ds[:a1_a].to_a).to eq([1, 0, 1, nil, 1])
      expect(@ds[:a1_b].to_a).to eq([1, 1, 0, nil, 1])
      expect(@ds[:a1_c].to_a).to eq([0, 1, 0, nil, 1])
    end
  end

  context ".crosstab_by_assignation" do
    it "" do
      v1 = DaruLite::Vector.new %w(a a a b b b c c c)
      v2 = DaruLite::Vector.new %w(a b c a b c a b c)
      v3 = DaruLite::Vector.new [0, 1, 0, 0, 1, 1, 0, 0, 1]
      df = DaruLite::DataFrame.crosstab_by_assignation(v1, v2, v3)

      expect(df[:_id].type).to eq(:object)
      expect(df['a'].type).to eq(:numeric)
      expect(df['b'].type).to eq(:numeric)

      ev_id = DaruLite::Vector.new %w(a b c)
      ev_a  = DaruLite::Vector.new [0, 0, 0]
      ev_b  = DaruLite::Vector.new [1, 1, 0]
      ev_c  = DaruLite::Vector.new [0, 1, 1]
      df2 = DaruLite::DataFrame.new({
        :_id => ev_id, 'a' => ev_a, 'b' => ev_b, 'c' => ev_c },
        order: ['a', 'b', 'c', :_id])

      expect(df2).to eq(df)
    end
  end

  context '#inspect' do
    subject { df.inspect }

    context 'empty' do
      let(:df) { DaruLite::DataFrame.new({}, order: %w[a b c])}
      it { is_expected.to eq %Q{
        |#<DaruLite::DataFrame(0x3)>
        |   a   b   c
      }.unindent}
    end

    context 'simple' do
      let(:df) { DaruLite::DataFrame.new({a: [1,2,3], b: [3,4,5], c: [6,7,8]}, name: 'test')}
      it { should == %Q{
        |#<DaruLite::DataFrame: test (3x3)>
        |       a   b   c
        |   0   1   3   6
        |   1   2   4   7
        |   2   3   5   8
       }.unindent}
    end

    context 'if index name is set' do
      context 'single index with name' do
        let(:df) { DaruLite::DataFrame.new({a: [1,2,3], b: [3,4,5], c: [6,7,8]},
        name: 'test')}
        before { df.index.name = 'index_name' }
        it { should == %Q{
          |#<DaruLite::DataFrame: test (3x3)>
          | index_name          a          b          c
          |          0          1          3          6
          |          1          2          4          7
          |          2          3          5          8
         }.unindent}
      end

      context 'MultiIndex with name' do
        let(:mi) { DaruLite::MultiIndex.new(
                levels: [[:a,:b,:c], [:one, :two]],
                labels: [[0,0,1,1,2,2], [0,1,0,1,0,1]], name: ['s1', 's2']) }
        let(:df) { DaruLite::DataFrame.new({
          a: [11, 12, 13, 14, 15, 16], b: [21, 22, 23, 24, 25, 26]},
            name: 'test', index: mi)}
        it { should == %Q{
          |#<DaruLite::DataFrame: test (6x2)>
          |  s1  s2   a   b
          |   a one  11  21
          |     two  12  22
          |   b one  13  23
          |     two  14  24
          |   c one  15  25
          |     two  16  26
         }.unindent}
      end

    end

    context 'no name' do
      let(:df) { DaruLite::DataFrame.new({a: [1,2,3], b: [3,4,5], c: [6,7,8]})}
      it { should == %Q{
        |#<DaruLite::DataFrame(3x3)>
        |       a   b   c
        |   0   1   3   6
        |   1   2   4   7
        |   2   3   5   8
       }.unindent}
    end

    context 'with nils' do
      let(:df) { DaruLite::DataFrame.new({a: [1,nil,3], b: [3,4,5], c: [6,7,nil]}, name: 'test')}
      it { is_expected.to eq %Q{
        |#<DaruLite::DataFrame: test (3x3)>
        |       a   b   c
        |   0   1   3   6
        |   1 nil   4   7
        |   2   3   5 nil
       }.unindent}
    end

    context 'with integers as vectors names' do
      let(:df) { DaruLite::DataFrame.new({ 1 => [1,2,3], b: [3,4,5], c: [6,7,8] }, name: 'test')}

      it { is_expected.to eq %Q{
        |#<DaruLite::DataFrame: test (3x3)>
        |       1   b   c
        |   0   1   3   6
        |   1   2   4   7
        |   2   3   5   8
       }.unindent}
    end

    context 'very long' do
      let(:df) { DaruLite::DataFrame.new({a: [1,1,1]*20, b: [1,1,1]*20, c: [1,1,1]*20}, name: 'test')}
      it { is_expected.to eq %Q{
        |#<DaruLite::DataFrame: test (60x3)>
        |       a   b   c
        |   0   1   1   1
        |   1   1   1   1
        |   2   1   1   1
        |   3   1   1   1
        |   4   1   1   1
        |   5   1   1   1
        |   6   1   1   1
        |   7   1   1   1
        |   8   1   1   1
        |   9   1   1   1
        |  10   1   1   1
        |  11   1   1   1
        |  12   1   1   1
        |  13   1   1   1
        |  14   1   1   1
        |  15   1   1   1
        |  16   1   1   1
        |  17   1   1   1
        |  18   1   1   1
        |  19   1   1   1
        |  20   1   1   1
        |  21   1   1   1
        |  22   1   1   1
        |  23   1   1   1
        |  24   1   1   1
        |  25   1   1   1
        |  26   1   1   1
        |  27   1   1   1
        |  28   1   1   1
        |  29   1   1   1
        | ... ... ... ...
       }.unindent}
    end

    context 'long data lines' do
      let(:df) { DaruLite::DataFrame.new({a: [1,2,3], b: [4,5,6], c: ['this is ridiculously long',nil,nil]}, name: 'test')}
      it { is_expected.to eq %Q{
        |#<DaruLite::DataFrame: test (3x3)>
        |                     a          b          c
        |          0          1          4 this is ri
        |          1          2          5        nil
        |          2          3          6        nil
       }.unindent}
    end

    context 'index is a MultiIndex' do
      let(:df) {
        DaruLite::DataFrame.new(
          {
            a:   [1,2,3,4,5,6,7],
            b: %w[a b c d e f g]
          }, index: DaruLite::MultiIndex.from_tuples([
                %w[foo one],
                %w[foo two],
                %w[foo three],
                %w[bar one],
                %w[bar two],
                %w[bar three],
                %w[baz one],
             ]),
             name: 'test'
        )
      }

      it { is_expected.to eq %Q{
        |#<DaruLite::DataFrame: test (7x2)>
        |                 a     b
        |   foo   one     1     a
        |         two     2     b
        |       three     3     c
        |   bar   one     4     d
        |         two     5     e
        |       three     6     f
        |   baz   one     7     g
      }.unindent}
    end

    context 'vectors is a MultiIndex' do
    end

    context 'spacing and threshold settings' do
    end
  end

  context "#by_single_key" do
    let(:df) { DaruLite::DataFrame.new(a: [1, 2, 3], b: [4, 5, 6] ) }

    it 'raise error when vector is missing from dataframe' do
      expect { df[:c] }.to raise_error(IndexError, /Specified vector c does not exist/)
    end
  end
end if mri?
