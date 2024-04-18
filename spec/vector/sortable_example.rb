shared_examples_for 'a sortable Vector' do |dtype|
  describe "#reorder!" do
    subject { vector_with_dtype.reorder!([3, 2, 1, 0]) }

    let(:vector_with_dtype) do
      DaruLite::Vector.new(
        [1, 2, 3, 4],
        index: [:a, :b, :c, :d],
        dtype:
      )
    end
    let(:arranged_vector) do
      DaruLite::Vector.new([4,3,2,1], index: [:d, :c, :b, :a], dtype:)
    end

    before { subject }

    it "rearranges with passed order" do
      expect(vector_with_dtype).to eq arranged_vector
    end

    it "doesn't change dtype" do
      expect(vector_with_dtype.data.class).to eq arranged_vector.data.class
    end
  end


  context "#sort" do
    context DaruLite::Index do
      let(:vector) do
        DaruLite::Vector.new([33, 2, 15, 332, 1], name: :dv, index: [:a, :b, :c, :d, :e])
      end

      it "sorts the vector with defaults and returns a new vector, preserving indexing" do
        expect(vector.sort).to eq(
          DaruLite::Vector.new([1,2,15,33,332], name: :dv, index: [:e, :b, :c, :a, :d])
        )
      end

      it "sorts the vector in descending order" do
        expect(vector.sort(ascending: false)).to eq(
          DaruLite::Vector.new([332,33,15,2,1], name: :dv, index: [:d, :a, :c, :b, :e])
        )
      end

      context 'when a block is passed' do
        subject { vector.sort { |a,b| a.length <=> b.length } }

        let(:vector) { DaruLite::Vector.new ["My Jazz Guitar", "Jazz", "My", "Guitar"] }

        it "sorts vector accordingly" do
          expect(subject).to eq(
            DaruLite::Vector.new(["My", "Jazz", "Guitar", "My Jazz Guitar"], index: [2, 1, 3, 0])
          )
        end
      end

      context 'when vector contains nils and numeric data' do
        let(:vector) { DaruLite::Vector.new([22, 4, nil, 111, nil, 2]) }

        it "places nils near the beginning of the vector when sorting ascendingly" do
          expect(vector.sort).to eq(
            DaruLite::Vector.new([nil, nil, 2, 4, 22, 111], index: [2, 4, 5, 1, 0, 3])
          )
        end if dtype == :array

        it "places nils near the beginning of the vector when sorting descendingly" do
          expect(vector.sort(ascending: false)).to eq(
            DaruLite::Vector.new [111, 22, 4, 2, nil, nil], index: [3, 0, 1, 5, 4, 2]
          )
        end
      end

      context 'when vector contains nils and non-numeric data' do
        let(:vector) { DaruLite::Vector.new(['a','b', nil, 'aa', '1234', nil]) }

        it "correctly sorts vector in ascending order" do
          expect(vector.sort(ascending: true)).to eq(
            DaruLite::Vector.new([nil, nil, '1234', 'a', 'aa', 'b'], index: [2, 5, 4, 0, 3, 1])
          )
        end

        it "correctly sorts vector in descending order" do
          expect(vector.sort(ascending: false)).to eq(
            DaruLite::Vector.new(['b', 'aa', 'a', '1234', nil, nil], index: [1, 3, 0, 4, 5, 2])
          )
        end
      end
    end

    context DaruLite::MultiIndex do
      let(:multi_index) do
        DaruLite::MultiIndex.from_tuples([
          [:a, :one,   :foo],
          [:a, :two,   :bar],
          [:b, :one,   :bar],
          [:b, :two,   :baz],
          [:b, :three, :bar]
        ])
      end
      let(:vector) do
        DaruLite::Vector.new(
          [44, 22, 111, 0, -56],
          index: multi_index,
          name: :unsorted,
          dtype:
        )
      end

      it "sorts vector" do
        mi_asc = DaruLite::MultiIndex.from_tuples([
          [:b, :three, :bar],
          [:b, :two,   :baz],
          [:a, :two,   :bar],
          [:a, :one,   :foo],
          [:b, :one,   :bar]
        ])
        expect(vector.sort).to eq(
          DaruLite::Vector.new([-56,0,22,44,111], index: mi_asc, name: :ascending, dtype:)
        )
      end

      it "sorts in descending" do
        mi_dsc = DaruLite::MultiIndex.from_tuples([
          [:b, :one, :bar],
          [:a, :one, :foo],
          [:a, :two, :bar],
          [:b, :two, :baz],
          [:b, :three, :bar]
        ])
        expect(vector.sort(ascending: false)).to eq(
          DaruLite::Vector.new([111, 44, 22, 0, -56], index: mi_dsc, name: :descending, dtype:)
        )
      end

      it "sorts using the supplied block" do
        mi_abs = DaruLite::MultiIndex.from_tuples([
          [:b, :two,   :baz],
          [:a, :two,   :bar],
          [:a, :one,   :foo],
          [:b, :three, :bar],
          [:b, :one,   :bar]
        ])
        expect(vector.sort { |a,b| a.abs <=> b.abs }).to eq(
          DaruLite::Vector.new([0, 22, 44, -56, 111], index: mi_abs, name: :sort_abs, dtype:)
        )
      end
    end

    context DaruLite::CategoricalIndex do
      let(:idx) { DaruLite::CategoricalIndex.new [:a, 1, :a, 1, :c] }
      let(:dv_numeric) { DaruLite::Vector.new [4, 5, 3, 2, 1], index: idx }
      let(:dv_string) { DaruLite::Vector.new ['xxxx', 'zzzzz', 'ccc', 'bb', 'a'], index: idx }
      let(:dv_nil) { DaruLite::Vector.new [3, nil, 2, 1, -1], index: idx }

      context "increasing order" do
        context "numeric" do
          subject { dv_numeric.sort }

          its(:size) { is_expected.to eq 5 }
          its(:to_a) { is_expected.to eq [1, 2, 3, 4, 5] }
          its(:'index.to_a') { is_expected.to eq [:c, 1, :a, :a, 1] }
        end

        context "non-numeric" do
          subject { dv_string.sort }

          its(:size) { is_expected.to eq 5 }
          its(:to_a) { is_expected.to eq ['a', 'bb', 'ccc', 'xxxx', 'zzzzz'] }
          its(:'index.to_a') { is_expected.to eq [:c, 1, :a, :a, 1] }
        end

        context "block" do
          subject { dv_string.sort { |a, b| a.length <=> b.length } }

          its(:to_a) { is_expected.to eq ['a', 'bb', 'ccc', 'xxxx', 'zzzzz'] }
          its(:'index.to_a') { is_expected.to eq [:c, 1, :a, :a, 1] }
        end

        context "nils" do
          subject { dv_nil.sort }

          its(:to_a) { is_expected.to eq [nil, -1, 1, 2, 3] }
          its(:'index.to_a') { is_expected.to eq [1, :c, 1, :a, :a] }
        end
      end

      context "decreasing order" do
        context "numeric" do
          subject { dv_numeric.sort(ascending: false) }

          its(:size) { is_expected.to eq 5 }
          its(:to_a) { is_expected.to eq [5, 4, 3, 2, 1] }
          its(:'index.to_a') { is_expected.to eq [1, :a, :a, 1, :c] }
        end

        context "non-numeric" do
          subject { dv_string.sort(ascending: false) }

          its(:size) { is_expected.to eq 5 }
          its(:to_a) { is_expected.to eq ['zzzzz', 'xxxx', 'ccc', 'bb', 'a'] }
          its(:'index.to_a') { is_expected.to eq [1, :a, :a, 1, :c] }
        end

        context "block" do
          subject do
            dv_string.sort(ascending: false) { |a, b| a.length <=> b.length }
          end

          its(:to_a) { is_expected.to eq ['zzzzz', 'xxxx', 'ccc', 'bb', 'a'] }
          its(:'index.to_a') { is_expected.to eq [1, :a, :a, 1, :c] }
        end

        context "nils" do
          subject { dv_nil.sort(ascending: false) }

          its(:to_a) { is_expected.to eq [3, 2, 1, -1, nil] }
          its(:'index.to_a') { is_expected.to eq [:a, :a, 1, :c, 1] }
        end
      end
    end
  end

  describe "#sort_by_index" do
    let(:asc) { vector.sort_by_index }
    let(:desc) { vector.sort_by_index(ascending: false) }

    context 'numeric vector' do
      let(:vector) { DaruLite::Vector.new [11, 13, 12], index: [23, 21, 22] }

      specify { expect(asc.to_a).to eq [13, 12, 11] }
      specify { expect(desc.to_a).to eq [11, 12, 13] }
    end

    context 'mix variable type index' do
      let(:vector) { DaruLite::Vector.new [11, Float::NAN, nil], index: [21, 23, 22] }

      specify { expect(asc.to_a).to eq [11, nil, Float::NAN] }
      specify { expect(desc.to_a).to eq [Float::NAN, nil, 11] }
    end
  end
end
