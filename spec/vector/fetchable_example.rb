shared_examples_for 'a fetchable Vector' do |dtype|
  describe "#[]" do
    context DaruLite::Index do
      let(:vector) do
        DaruLite::Vector.new(
          [1,2,3,4,5],
          name: :yoga,
          index: [:yoda, :anakin, :obi, :padme, :r2d2],
          dtype:
        )
      end

      it "returns an element after passing an index" do
        expect(vector[:yoda]).to eq(1)
      end

      it "returns an element after passing a numeric index" do
        expect(vector[0]).to eq(1)
      end

      it "returns a vector with given indices for multiple indices" do
        expect(vector[:yoda, :anakin]).to eq(
          DaruLite::Vector.new([1, 2], name: :yoda, index: [:yoda, :anakin], dtype:)
        )
      end

      it "returns a vector with given indices for multiple numeric indices" do
        expect(vector[0, 1]).to eq(
          DaruLite::Vector.new([1, 2], name: :yoda, index: [:yoda, :anakin], dtype:)
        )
      end

      it "returns a vector when specified symbol Range" do
        expect(vector[:yoda..:anakin]).to eq(
          DaruLite::Vector.new([1, 2], index: [:yoda, :anakin], name: :yoga, dtype:)
        )
      end

      it "returns a vector when specified numeric Range" do
        expect(vector[3..4]).to eq(
          DaruLite::Vector.new([4,5], name: :yoga, index: [:padme, :r2d2], dtype:)
        )
      end

      it "returns correct results for index of multiple index" do
        v = DaruLite::Vector.new([1, 2, 3, 4], index: ['a', 'c', 1, :a])
        expect(v['a']).to eq(1)
        expect(v[:a]).to eq(4)
        expect(v[1]).to eq(3)
        expect(v[0]).to eq(1)
      end

      it "raises exception for invalid index" do
        expect { vector[:foo] }.to raise_error(IndexError)
        expect { vector[:obi, :foo] }.to raise_error(IndexError)
      end
    end

    describe DaruLite::MultiIndex do
      let(:tuples) do
        [
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
          [:c,:two,:bar],
          [:d,:one,:foo]
        ]
      end
      let(:multi_index) { DaruLite::MultiIndex.from_tuples(tuples) }
      let(:vector) do
        DaruLite::Vector.new(
          Array.new(13) { |i| i },
          index: multi_index,
          dtype:,
          name: :mi_vector
        )
      end

      it "returns a single element when passed a row number" do
        expect(vector[1]).to eq(1)
      end

      it "returns a single element when passed the full tuple" do
        expect(vector[:a, :one, :baz]).to eq(1)
      end

      it "returns sub vector when passed first layer of tuple" do
        index = DaruLite::MultiIndex.from_tuples([
          [:one,:bar],
          [:one,:baz],
          [:two,:bar],
          [:two,:baz]]
        )
        expect(vector[:a]).to eq(
          DaruLite::Vector.new([0,1,2,3], index:, dtype:, name: :sub_vector)
        )
      end

      it "returns sub vector when passed first and second layer of tuple" do
        index = DaruLite::MultiIndex.from_tuples([[:foo], [:bar]])
        expect(vector[:c,:two]).to eq(
          DaruLite::Vector.new([10,11], index:, dtype:, name: :sub_sub_vector)
        )
      end

      it "returns sub vector not a single element when passed the partial tuple" do
        index = DaruLite::MultiIndex.from_tuples([[:foo]])
        expect(vector[:d, :one]).to eq(
          DaruLite::Vector.new([12], index:, dtype:, name: :sub_sub_vector)
        )
      end

      it "returns a vector with corresponding MultiIndex when specified numeric Range" do
        index = DaruLite::MultiIndex.from_tuples([
          [:a,:two,:baz],
          [:b,:one,:bar],
          [:b,:two,:bar],
          [:b,:two,:baz],
          [:b,:one,:foo],
          [:c,:one,:bar],
          [:c,:one,:baz]
        ])
        expect(vector[3..9]).to eq(
          DaruLite::Vector.new([3,4,5,6,7,8,9], index:, dtype:, name: :slice)
        )
      end

      it "raises exception for invalid index" do
        expect { vector[:foo] }.to raise_error(IndexError)
        expect { vector[:a, :two, :foo] }.to raise_error(IndexError)
        expect { vector[:x, :one] }.to raise_error(IndexError)
      end
    end

    context DaruLite::CategoricalIndex do
      # before { skip }
      context "non-numerical index" do
        let (:idx) { DaruLite::CategoricalIndex.new [:a, :b, :a, :a, :c] }
        let (:dv)  { DaruLite::Vector.new 'a'..'e', index: idx }

        context "single category" do
          context "multiple instances" do
            subject { dv[:a] }

            it { is_expected.to be_a DaruLite::Vector }
            its(:size) { is_expected.to eq 3 }
            its(:to_a) { is_expected.to eq  ['a', 'c', 'd'] }
            its(:index) { is_expected.to eq(
              DaruLite::CategoricalIndex.new([:a, :a, :a])) }
          end

          context "single instance" do
            subject { dv[:c] }

            it { is_expected.to eq 'e' }
          end
        end

        context "multiple categories" do
          subject { dv[:a, :c] }

          it { is_expected.to be_a DaruLite::Vector }
          its(:size) { is_expected.to eq 4 }
          its(:to_a) { is_expected.to eq  ['a', 'c', 'd', 'e'] }
          its(:index) { is_expected.to eq(
            DaruLite::CategoricalIndex.new([:a, :a, :a, :c])) }
        end

        context "multiple positional indexes" do
          subject { dv[0, 1, 2] }

          it { is_expected.to be_a DaruLite::Vector }
          its(:size) { is_expected.to eq 3 }
          its(:to_a) { is_expected.to eq ['a', 'b', 'c'] }
          its(:index) { is_expected.to eq(
            DaruLite::CategoricalIndex.new([:a, :b, :a])) }
        end

        context "single positional index" do
          subject { dv[1] }

          it { is_expected.to eq 'b' }
        end

        context "invalid category" do
          it { expect { dv[:x] }.to raise_error IndexError }
        end

        context "invalid positional index" do
          it { expect { dv[30] }.to raise_error IndexError }
        end
      end

      context "numerical index" do
        let (:idx) { DaruLite::CategoricalIndex.new [1, 1, 2, 2, 3] }
        let (:dv)  { DaruLite::Vector.new 'a'..'e', index: idx }

        context "single category" do
          context "multiple instances" do
            subject { dv[1] }

            it { is_expected.to be_a DaruLite::Vector }
            its(:size) { is_expected.to eq 2 }
            its(:to_a) { is_expected.to eq  ['a', 'b'] }
            its(:index) { is_expected.to eq(
              DaruLite::CategoricalIndex.new([1, 1])) }
          end

          context "single instance" do
            subject { dv[3] }

            it { is_expected.to eq 'e' }
          end
        end
      end
    end
  end

  describe "#at" do
    context DaruLite::Index do
      let (:idx) { DaruLite::Index.new [1, 0, :c] }
      let (:dv) { DaruLite::Vector.new ['a', 'b', 'c'], index: idx }

      let (:idx_dt) { DaruLite::DateTimeIndex.new(['2017-01-01', '2017-02-01', '2017-03-01']) }
      let (:dv_dt) { DaruLite::Vector.new(['a', 'b', 'c'], index: idx_dt) }

      context "single position" do
        it { expect(dv.at 1).to eq 'b' }
      end

      context "multiple positions" do
        subject { dv.at 0, 2 }

        it { is_expected.to be_a DaruLite::Vector }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq ['a', 'c'] }
        its(:'index.to_a') { is_expected.to eq [1, :c] }
      end

      context "invalid position" do
        it { expect { dv.at 3 }.to raise_error IndexError }
      end

      context "invalid positions" do
        it { expect { dv.at 2, 3 }.to raise_error IndexError }
      end

      context "range" do
        subject { dv.at 0..1 }

        it { is_expected.to be_a DaruLite::Vector }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq ['a', 'b'] }
        its(:'index.to_a') { is_expected.to eq [1, 0] }
      end

      context "range with negative end" do
        subject { dv.at 0..-2 }

        it { is_expected.to be_a DaruLite::Vector }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq ['a', 'b'] }
        its(:'index.to_a') { is_expected.to eq [1, 0] }
      end

      context "range with single element" do
        subject { dv.at 0..0 }

        it { is_expected.to be_a DaruLite::Vector }
        its(:size) { is_expected.to eq 1 }
        its(:to_a) { is_expected.to eq ['a'] }
        its(:'index.to_a') { is_expected.to eq [1] }
      end

      context "Splat .at on DateTime index" do
        subject { dv_dt.at(*[1,2]) }

        it { is_expected.to be_a DaruLite::Vector }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq ['b', 'c'] }
        its(:'index.to_a') { is_expected.to eq ['2017-02-01', '2017-03-01'] }
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
      let (:dv) { DaruLite::Vector.new 1..4, index: idx }

      context "single position" do
        it { expect(dv.at 1).to eq 2 }
      end

      context "multiple positions" do
        subject { dv.at 2, 3 }

        it { is_expected.to be_a DaruLite::Vector }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq [3, 4] }
        its(:'index.to_a') { is_expected.to eq [[:b, :two, :bar],
          [:a, :two, :baz]] }
      end

      context "invalid position" do
        it { expect { dv.at 4 }.to raise_error IndexError }
      end

      context "invalid positions" do
        it { expect { dv.at 2, 4 }.to raise_error IndexError }
      end

      context "range" do
        subject { dv.at 2..3 }

        it { is_expected.to be_a DaruLite::Vector }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq [3, 4] }
        its(:'index.to_a') { is_expected.to eq [[:b, :two, :bar],
          [:a, :two, :baz]] }
      end

      context "range with negative end" do
        subject { dv.at 2..-1 }

        it { is_expected.to be_a DaruLite::Vector }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq [3, 4] }
        its(:'index.to_a') { is_expected.to eq [[:b, :two, :bar],
          [:a, :two, :baz]] }
      end

      context "range with single element" do
        subject { dv.at 2..2 }

        it { is_expected.to be_a DaruLite::Vector }
        its(:size) { is_expected.to eq 1 }
        its(:to_a) { is_expected.to eq [3] }
        its(:'index.to_a') { is_expected.to eq [[:b, :two, :bar]] }
      end
    end

    context DaruLite::CategoricalIndex do
      let (:idx) { DaruLite::CategoricalIndex.new [:a, 1, 1, :a, :c] }
      let (:dv)  { DaruLite::Vector.new 'a'..'e', index: idx }

      context "multiple positional indexes" do
        subject { dv.at 0, 1, 2 }

        it { is_expected.to be_a DaruLite::Vector }
        its(:size) { is_expected.to eq 3 }
        its(:to_a) { is_expected.to eq ['a', 'b', 'c'] }
        its(:index) { is_expected.to eq(
          DaruLite::CategoricalIndex.new([:a, 1, 1])) }
      end

      context "single positional index" do
        subject { dv.at 1 }

        it { is_expected.to eq 'b' }
      end

      context "invalid position" do
        it { expect { dv.at 5 }.to raise_error IndexError }
      end

      context "invalid positions" do
        it { expect { dv.at 2, 5 }.to raise_error IndexError }
      end

      context "range" do
        subject { dv.at 0..2 }

        it { is_expected.to be_a DaruLite::Vector }
        its(:size) { is_expected.to eq 3 }
        its(:to_a) { is_expected.to eq ['a', 'b', 'c'] }
        its(:index) { is_expected.to eq(
          DaruLite::CategoricalIndex.new([:a, 1, 1])) }
      end

      context "range with negative end" do
        subject { dv.at 0..-3 }

        it { is_expected.to be_a DaruLite::Vector }
        its(:size) { is_expected.to eq 3 }
        its(:to_a) { is_expected.to eq ['a', 'b', 'c'] }
        its(:index) { is_expected.to eq(
          DaruLite::CategoricalIndex.new([:a, 1, 1])) }
      end

      context "range with single element" do
        subject { dv.at 0..0 }

        it { is_expected.to be_a DaruLite::Vector }
        its(:size) { is_expected.to eq 1 }
        its(:to_a) { is_expected.to eq ['a'] }
        its(:index) { is_expected.to eq(
          DaruLite::CategoricalIndex.new([:a])) }
      end
    end
  end

  describe '#head' do
    subject(:vector) { DaruLite::Vector.new (1..20).to_a, dtype: }

    it 'takes 10 by default' do
      expect(vector.head).to eq DaruLite::Vector.new (1..10).to_a
    end

    it 'takes num if provided' do
      expect(vector.head(3)).to eq DaruLite::Vector.new (1..3).to_a
    end

    it 'does not fail on too large num' do
      expect(vector.head(3000)).to eq vector
    end
  end

  describe '#tail' do
    subject(:vector) { DaruLite::Vector.new (1..20).to_a, dtype: }

    it 'takes 10 by default' do
      expect(vector.tail).to eq DaruLite::Vector.new (11..20).to_a, index: (10..19).to_a
    end

    it 'takes num if provided' do
      expect(vector.tail(3)).to eq DaruLite::Vector.new (18..20).to_a, index: (17..19).to_a
    end

    it 'does not fail on too large num' do
      expect(vector.tail(3000)).to eq vector
    end
  end

  describe '#last' do
    subject(:vector) { DaruLite::Vector.new (1..20).to_a, dtype: }

    it 'takes 1 by default' do
      expect(vector.last).to eq 20
    end

    it 'takes num if provided' do
      expect(vector.last(3)).to eq DaruLite::Vector.new (18..20).to_a, index: (17..19).to_a
    end

    it 'does not fail on too large num' do
      expect(vector.last(3000)).to eq vector
    end
  end
end
