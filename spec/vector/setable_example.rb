shared_examples_for 'a setable Vector' do |dtype|
  describe "#[]=" do
    context DaruLite::Index do
      let(:vector) do
        DaruLite::Vector.new(
          [1,2,3,4,5],
          name: :yoga,
          index: [:yoda, :anakin, :obi, :padme, :r2d2],
          dtype:
        )
      end

      it "assigns at the specified index" do
        vector[:yoda] = 666
        expect(vector[:yoda]).to eq(666)
      end

      it "assigns at the specified Integer index" do
        vector[0] = 666
        expect(vector[:yoda]).to eq(666)
      end

      it "sets dtype to Array if a nil is assigned" do
        vector[0] = nil
        expect(vector.dtype).to eq(:array)
      end

      context 'mixed index Vector' do
        let(:vector) do
          DaruLite::Vector.new([1, 2, 3, 4], index: ['a', :a, 0, 66])
        end

        it "assigns correctly" do
          vector['a'] = 666
          expect(vector['a']).to eq(666)

          vector[0] = 666
          expect(vector[0]).to eq(666)

          vector[3] = 666
          expect(vector[3]).to eq(666)

          expect(vector).to eq(
            DaruLite::Vector.new(
              [666, 2, 666, 666],
              index: ['a', :a, 0, 66])
            )
        end
      end
    end

    context DaruLite::MultiIndex do
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
          [:c,:two,:bar]
        ]
      end
      let(:multi_index) { DaruLite::MultiIndex.from_tuples(tuples) }
      let(:vector) do
        DaruLite::Vector.new(
          Array.new(12) { |i| i },
          index: multi_index,
          dtype:,
          name: :mi_vector
        )
      end

      it "assigns all lower layer indices when specified a first layer index" do
        vector[:b] = 69
        expect(vector).to eq(
          DaruLite::Vector.new([0, 1, 2, 3, 69, 69, 69, 69, 8, 9, 10, 11],
            index: multi_index,
            name: :top_layer_assignment,
            dtype:
          )
        )
      end

      it "assigns all lower indices when specified first and second layer index" do
        vector[:b, :one] = 69
        expect(vector).to eq(
          DaruLite::Vector.new([0, 1, 2, 3, 69, 5, 6, 69, 8, 9, 10, 11],
            index: multi_index,
            name: :second_layer_assignment,
            dtype:
          )
        )
      end

      it "assigns just the precise value when specified complete tuple" do
        vector[:b, :one, :foo] = 69
        expect(vector).to eq(
          DaruLite::Vector.new([0, 1, 2, 3, 4, 5, 6, 69, 8, 9, 10, 11],
            index: multi_index,
            name: :precise_assignment,
            dtype:
          )
        )
      end

      it "assigns correctly when numeric index" do
        vector[7] = 69
        expect(vector).to eq(
          DaruLite::Vector.new([0, 1, 2, 3, 4, 5, 6, 69, 8, 9, 10, 11],
            index: multi_index,
            name: :precise_assignment,
            dtype:
          )
        )
      end

      it "fails predictably on unknown index" do
        expect { vector[:d] = 69 }.to raise_error(IndexError)
        expect { vector[:b, :three] = 69 }.to raise_error(IndexError)
        expect { vector[:b, :two, :test] = 69 }.to raise_error(IndexError)
      end
    end

    context DaruLite::CategoricalIndex do
      subject { vector }

      context "non-numerical index" do
        let (:idx) { DaruLite::CategoricalIndex.new [:a, :b, :a, :a, :c] }
        let (:vector)  { DaruLite::Vector.new 'a'..'e', index: idx }

        context "single category" do
          context "multiple instances" do
            before { vector[:a] = 'x' }

            its(:size) { is_expected.to eq 5 }
            its(:to_a) { is_expected.to eq  ['x', 'b', 'x', 'x', 'e'] }
            its(:index) { is_expected.to eq idx }
          end

          context "single instance" do
            before { vector[:b] = 'x' }

            its(:size) { is_expected.to eq 5 }
            its(:to_a) { is_expected.to eq  ['a', 'x', 'c', 'd', 'e'] }
            its(:index) { is_expected.to eq idx }
          end
        end

        context "multiple categories" do
          before { vector[:a, :c] = 'x' }

          its(:size) { is_expected.to eq 5 }
          its(:to_a) { is_expected.to eq  ['x', 'b', 'x', 'x', 'x'] }
          its(:index) { is_expected.to eq idx }
        end

        context "multiple positional indexes" do
          before { vector[0, 1, 2] = 'x' }

          its(:size) { is_expected.to eq 5 }
          its(:to_a) { is_expected.to eq ['x', 'x', 'x', 'd', 'e'] }
          its(:index) { is_expected.to eq idx }
        end

        context "single positional index" do
          before { vector[1] = 'x' }

          its(:size) { is_expected.to eq 5 }
          its(:to_a) { is_expected.to eq ['a', 'x', 'c', 'd', 'e'] }
          its(:index) { is_expected.to eq idx }
        end

        context "invalid category" do
          it { expect { vector[:x] = 'x' }.to raise_error IndexError }
        end

        context "invalid positional index" do
          it { expect { vector[30] = 'x'}.to raise_error IndexError }
        end
      end

      context "numerical index" do
        let (:idx) { DaruLite::CategoricalIndex.new [1, 1, 2, 2, 3] }
        let (:vector)  { DaruLite::Vector.new 'a'..'e', index: idx }

        context "single category" do
          before { vector[1] = 'x' }

          its(:size) { is_expected.to eq 5 }
          its(:to_a) { is_expected.to eq ['x', 'x', 'c', 'd', 'e'] }
          its(:index) { is_expected.to eq idx }
        end

        context "multiple categories" do
          before { vector[1, 2] = 'x' }

          its(:size) { is_expected.to eq 5 }
          its(:to_a) { is_expected.to eq ['x', 'x', 'x', 'x', 'e'] }
          its(:index) { is_expected.to eq idx }
        end
      end
    end
  end

  describe "#set_at" do
    context DaruLite::Index do
      let (:idx) { DaruLite::Index.new [1, 0, :c] }
      let (:dv) { DaruLite::Vector.new ['a', 'b', 'c'], index: idx }

      context "single position" do
        subject { dv }
        before { dv.set_at [1], 'x' }

        its(:to_a) { is_expected.to eq ['a', 'x', 'c'] }
      end

      context "multiple positions" do
        subject { dv }
        before { dv.set_at [0, 2], 'x' }

        its(:to_a) { is_expected.to eq ['x', 'b', 'x'] }
      end

      context "invalid position" do
        it { expect { dv.set_at [3], 'x' }.to raise_error IndexError }
      end

      context "invalid positions" do
        it { expect { dv.set_at [2, 3], 'x' }.to raise_error IndexError }
      end
    end

    context DaruLite::MultiIndex do
      let(:idx) do
        DaruLite::MultiIndex.from_tuples [
          [:a,:one,:bar],
          [:a,:one,:baz],
          [:b,:two,:bar],
          [:a,:two,:baz],
        ]
      end
      let(:dv) { DaruLite::Vector.new 1..4, index: idx }

      context "single position" do
        subject { dv }
        before { dv.set_at [1], 'x' }

        its(:to_a) { is_expected.to eq [1, 'x', 3, 4] }
      end

      context "multiple positions" do
        subject { dv }
        before { dv.set_at [2, 3], 'x' }

        its(:to_a) { is_expected.to eq [1, 2, 'x', 'x'] }
      end

      context "invalid position" do
        it { expect { dv.set_at [4], 'x' }.to raise_error IndexError }
      end

      context "invalid positions" do
        it { expect { dv.set_at [2, 4], 'x' }.to raise_error IndexError }
      end
    end

    context DaruLite::CategoricalIndex do
      let (:idx) { DaruLite::CategoricalIndex.new [:a, 1, 1, :a, :c] }
      let (:dv)  { DaruLite::Vector.new 'a'..'e', index: idx }

      context "multiple positional indexes" do
        subject { dv }
        before { dv.set_at [0, 1, 2], 'x' }

        its(:to_a) { is_expected.to eq ['x', 'x', 'x', 'd', 'e'] }
      end

      context "single positional index" do
        subject { dv }
        before { dv.set_at [1], 'x' }

        its(:to_a) { is_expected.to eq ['a', 'x', 'c', 'd', 'e'] }
      end

      context "invalid position" do
        it { expect { dv.set_at [5], 'x' }.to raise_error IndexError }
      end

      context "invalid positions" do
        it { expect { dv.set_at [2, 5], 'x' }.to raise_error IndexError }
      end
    end
  end
end
