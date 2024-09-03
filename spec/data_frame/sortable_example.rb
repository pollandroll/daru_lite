shared_examples_for 'a sortable DataFrame' do
  describe '#order=' do
    let(:df) do
      DaruLite::DataFrame.new({
        a: [1, 2, 3],
        b: [4, 5, 6]
      }, order: [:a, :b])
    end

    context 'correct order' do
      before { df.order = [:b, :a] }
      subject { df }

      its(:'vectors.to_a') { is_expected.to eq [:b, :a] }
      its(:'b.to_a') { is_expected.to eq [4, 5, 6] }
      its(:'a.to_a') { is_expected.to eq [1, 2, 3] }
    end

    context 'insufficient vectors' do
      it { expect { df.order = [:a] }.to raise_error }
    end

    context 'wrong vectors' do
      it { expect { df.order = [:a, :b, 'b'] }.to raise_error }
    end
  end

  describe "#rotate_vectors" do
    subject { df.rotate_vectors(-1) }

    context "only one vector in the dataframe" do
      let(:df) { DaruLite::DataFrame.new({ a: [1,2,3] }) }

      it "return the dataframe without any change" do
        expect(subject).to eq(df)
      end
    end

    context "several vectors in the dataframe" do
      let(:df) do
        DaruLite::DataFrame.new({
          a: [1, 2, 3],
          b: [4, 5, 6],
          total: [5, 7, 9]
        })
      end
      let(:new_order) { [:total, :a, :b] }

      it "return the dataframe with the position of the last vector change to first" do
        expect(subject.vectors.to_a).to eq(new_order)
      end
    end

    context "vectors labels are of mixed classes" do
      let(:df) do
        DaruLite::DataFrame.new({
          a: [1, 2, 3],
          'b' => [4, 5, 6],
          nil => [5, 7, 9],
          1 => [10, 11, 12]
        })
      end
      let(:new_order) { [1, :a, 'b', nil] }

      it "return the dataframe with the position of the last vector change to first" do
        expect(subject.vectors.to_a).to eq(new_order)
      end
    end
  end


  describe "#sort!" do
    context DaruLite::Index do
      let(:df) do
        DaruLite::DataFrame.new(
          {
            a: [5,1,-6,7,5,5],
            b: [-2,-1,5,3,9,1],
            c: ['a','aa','aaa','aaaa','aaaaa','aaaaaa']
          }
        )
      end

      it "sorts according to given vector order (bang)" do
        a_sorter = lambda { |a| a }

        expect(df.sort!([:a], by: { a: a_sorter })).to eq(
          DaruLite::DataFrame.new({a: [-6,1,5,5,5,7], b: [5,-1,-2,9,1,3],
            c: ['aaa','aa','a','aaaaa','aaaaaa','aaaa']}, index: [2,1,0,4,5,3])
          )
      end

      it "sorts according to vector order using default lambdas (index re ordered according to the last vector) (bang)" do
        expect(df.sort!([:a, :b])).to eq(
          DaruLite::DataFrame.new({a: [-6,1,5,5,5,7], b: [5,-1,-2,1,9,3], c: ['aaa','aa','a','aaaaaa','aaaaa','aaaa']},
            index: [2,1,0,5,4,3])
          )
      end

      it "sorts both vectors in descending order" do
        expect(df.sort!([:a,:b], ascending: [false, false])).to eq(
          DaruLite::DataFrame.new({a: [7,5,5,5,1,-6], b: [3,9,1,-2,-1,5], c: ['aaaa','aaaaa','aaaaaa', 'a','aa', 'aaa'] },
            index: [3,4,5,0,1,2])
          )
      end

      it "sorts one vector in desc and other is asc" do
        expect(df.sort!([:a, :b], ascending: [false, true])).to eq(
          DaruLite::DataFrame.new({a: [7,5,5,5,1,-6], b: [3,-2,1,9,-1,5], c: ['aaaa','a','aaaaaa','aaaaa','aa','aaa']},
            index: [3,0,5,4,1,2])
          )
      end

      it "sorts many vectors" do
        d = DaruLite::DataFrame.new({a: [1,1,1,222,44,5,5,544], b: [44,44,333,222,111,554,22,3], c: [3,2,5,3,3,1,5,5]})

        expect(d.sort!([:a, :b, :c], ascending: [false, true, false])).to eq(
          DaruLite::DataFrame.new({a: [544,222,44,5,5,1,1,1], b: [3,222,111,22,554,44,44,333], c: [5,3,3,5,1,3,2,5]},
            index: [7,3,4,6,5,0,1,2])
          )
      end

      it "places nils at the beginning when sorting ascedingly" do
        d = DaruLite::DataFrame.new({a: [1,1,1,nil,44,5,5,nil], b: [44,44,333,222,111,554,22,3], c: [3,2,5,3,3,1,5,5]})

        expect(d.sort!([:a, :b, :c], ascending: [true, true, false])).to eq(
          DaruLite::DataFrame.new({a: [nil,nil,1,1,1,5,5,44], b: [3,222,44,44,333,22,554,111], c: [5,3,3,2,5,5,1,3]},
            index: [7,3,0,1,2,6,5,4])
          )
      end

      it "places nils at the beginning when sorting decendingly" do
        d = DaruLite::DataFrame.new({a: [1,1,1,nil,44,5,5,nil], b: [44,44,333,222,111,554,22,3], c: [3,2,5,3,3,1,5,5]})

        expect(d.sort!([:a, :b, :c], ascending: [false, true, false])).to eq(
          DaruLite::DataFrame.new({a: [nil,nil,44,5,5,1,1,1], b: [3,222,111,22,554,44,44,333], c: [5,3,3,5,1,3,2,5]},
            index: [7,3,4,6,5,0,1,2])
          )
      end

      it "sorts vectors of non-numeric types with nils in ascending order" do
        non_numeric = DaruLite::DataFrame.new({a: [5,1,-6,7,5,5], b: [nil,-1,1,nil,-1,1],
          c: ['aaa','aaa',nil,'baaa','xxx',nil]})

        expect(non_numeric.sort!([:c], ascending: [true])).to eq(
          DaruLite::DataFrame.new({a: [-6, 5, 5, 1, 7, 5], b: [1, 1, nil, -1, nil, -1],
            c: [nil, nil, "aaa", "aaa", "baaa", "xxx"]},
            index: [2, 5, 0, 1, 3, 4])
          )
      end

      it "sorts vectors of non-numeric types with nils in descending order" do
        non_numeric = DaruLite::DataFrame.new({a: [5,1,-6,7,5,5], b: [nil,-1,1,nil,-1,1],
          c: ['aaa','aaa',nil,'baaa','xxx',nil]})

        expect(non_numeric.sort!([:c], ascending: [false])).to eq(
          DaruLite::DataFrame.new({a: [-6, 5, 5, 7, 5, 1], b: [1, 1, -1, nil, nil, -1],
            c: [nil, nil, "xxx", "baaa", "aaa", "aaa"]},
            index: [2, 5, 4, 3, 0, 1])
          )
      end

      it "sorts vectors with block provided and handle nils automatically" do
        non_numeric = DaruLite::DataFrame.new({a: [5,1,-6,7,5,5], b: [nil,-1,1,nil,-1,1],
          c: ['aaa','aaa',nil,'baaa','xxx',nil]})

        expect(non_numeric.sort!([:b], by: {b: lambda { |a| a.abs } }, handle_nils: true)).to eq(
          DaruLite::DataFrame.new({a: [5, 7, 1, -6, 5, 5], b: [nil, nil, -1, 1, -1, 1],
            c: ["aaa", "baaa", "aaa", nil, "xxx", nil]},
            index: [0, 3, 1, 2, 4, 5])
          )
      end

      it "sorts vectors with block provided and nils handled manually" do
        non_numeric = DaruLite::DataFrame.new({a: [5,1,-6,7,5,5], b: [nil,-1,1,nil,-1,1],
          c: ['aaa','aaa',nil,'baaa','xxx',nil]})

      expect(non_numeric.sort!([:b], by: {b: lambda { |a| (a.nil?)?[1]:[0, a.abs]} }, handle_nils: false)).to eq(
        DaruLite::DataFrame.new({a: [1, -6, 5, 5, 5, 7], b: [-1, 1, -1, 1, nil, nil],
          c: ["aaa", nil, "xxx", nil, "aaa", "baaa"]},
          index: [1, 2, 4, 5, 0, 3])
        )
      end
    end

    context DaruLite::MultiIndex do
      pending
      it "sorts the DataFrame when specified full tuple" do
        df_mi.sort([[:a,:one,:bar]])
      end
    end
  end

  describe "#sort" do
    context DaruLite::Index do
      let(:df) do
        DaruLite::DataFrame.new({a: [5,1,-6,7,5,5], b: [-2,-1,5,3,9,1], c: ['a','aa','aaa','aaaa','aaaaa','aaaaaa']})
      end

      it "sorts according to given vector order (bang)" do
        a_sorter = lambda { |a| a }
        ans = df.sort([:a], by: { a: a_sorter })

        expect(ans).to eq(
          DaruLite::DataFrame.new({a: [-6,1,5,5,5,7], b: [5,-1,-2,9,1,3], c: ['aaa','aa','a','aaaaa','aaaaaa','aaaa']},
            index: [2,1,0,4,5,3])
          )
        expect(ans).to_not eq(df)
      end

      it "sorts according to vector order using default lambdas (index re ordered according to the last vector) (bang)" do
        ans = df.sort([:a, :b])
        expect(ans).to eq(
          DaruLite::DataFrame.new({a: [-6,1,5,5,5,7], b: [5,-1,-2,1,9,3], c: ['aaa','aa','a','aaaaaa','aaaaa','aaaa']},
            index: [2,1,0,5,4,3])
          )
        expect(ans).to_not eq(df)
      end
    end

    context DaruLite::MultiIndex do
      pending
    end

    context DaruLite::CategoricalIndex do
      let(:idx) { DaruLite::CategoricalIndex.new [:a, 1, :a, 1, :c] }
      let(:df) do
        DaruLite::DataFrame.new({
          a: [2, -1, 3, 4, 5],
          b: ['x', 'y', 'x', 'a', 'y'],
          c: [nil, nil, -2, 2, 1]
        }, index: idx)
      end

      context "ascending order" do
        context "single vector" do
          subject { df.sort [:a] }

          its(:'index.to_a') { is_expected.to eq [1, :a, :a, 1, :c] }
          its(:'a.to_a') { is_expected.to eq [-1, 2, 3, 4, 5] }
          its(:'b.to_a') { is_expected.to eq ['y', 'x', 'x', 'a', 'y'] }
          its(:'c.to_a') { is_expected.to eq [nil, nil, -2, 2, 1] }
        end

        context "multiple vectors" do
          subject { df.sort [:c, :b] }

          its(:'index.to_a') { is_expected.to eq [:a, 1, :a, :c, 1] }
          its(:'a.to_a') { is_expected.to eq [2, -1, 3, 5, 4] }
          its(:'b.to_a') { is_expected.to eq ['x', 'y', 'x', 'y', 'a'] }
          its(:'c.to_a') { is_expected.to eq [nil, nil, -2, 1, 2] }
        end

        context "block" do
          context "automatic handle nils" do
            subject do
              df.sort [:c], by: {c: lambda { |a| a.abs } }, handle_nils: true
            end

            its(:'index.to_a') { is_expected.to eq [:a, 1, :c, :a, 1] }
            its(:'a.to_a') { is_expected.to eq [2, -1, 5, 3, 4] }
            its(:'b.to_a') { is_expected.to eq ['x', 'y', 'y', 'x', 'a'] }
            its(:'c.to_a') { is_expected.to eq [nil, nil, 1, -2, 2] }
          end

          context "manually handle nils" do
            subject do
              df.sort [:c], by: {c: lambda { |a| (a.nil?)?[1]:[0,a.abs] } }
            end

            its(:'index.to_a') { is_expected.to eq [:c, :a, 1, :a, 1] }
            its(:'a.to_a') { is_expected.to eq [5, 3, 4, 2, -1] }
            its(:'b.to_a') { is_expected.to eq ['y', 'x', 'a', 'x', 'y'] }
            its(:'c.to_a') { is_expected.to eq [1, -2, 2, nil, nil] }
          end
        end
      end

      context "descending order" do
        context "single vector" do
          subject { df.sort [:a], ascending: false }

          its(:'index.to_a') { is_expected.to eq [:c, 1, :a, :a, 1] }
          its(:'a.to_a') { is_expected.to eq [5, 4, 3, 2, -1] }
          its(:'b.to_a') { is_expected.to eq ['y', 'a', 'x', 'x', 'y'] }
          its(:'c.to_a') { is_expected.to eq [1, 2, -2, nil, nil] }
        end

        context "multiple vectors" do
          subject { df.sort [:c, :b], ascending: false }

          its(:'index.to_a') { is_expected.to eq [1, :a, 1, :c, :a] }
          its(:'a.to_a') { is_expected.to eq [-1, 2, 4, 5, 3] }
          its(:'b.to_a') { is_expected.to eq ['y', 'x', 'a', 'y', 'x'] }
          its(:'c.to_a') { is_expected.to eq [nil, nil, 2, 1, -2] }
        end

        context "block" do
          context "automatic handle nils" do
            subject do
              df.sort [:c],
                by: {c: lambda { |a| a.abs } },
                handle_nils: true,
                ascending: false
            end

            its(:'index.to_a') { is_expected.to eq [:a, 1, :a, 1, :c] }
            its(:'a.to_a') { is_expected.to eq [2, -1, 3, 4, 5] }
            its(:'b.to_a') { is_expected.to eq ['x', 'y', 'x', 'a', 'y'] }
            its(:'c.to_a') { is_expected.to eq [nil, nil, -2, 2, 1] }
          end

          context "manually handle nils" do
            subject do
              df.sort [:c],
                by: {c: lambda { |a| (a.nil?)?[1]:[0,a.abs] } },
                ascending: false
            end

            its(:'index.to_a') { is_expected.to eq [:a, 1, :a, 1, :c] }
            its(:'a.to_a') { is_expected.to eq [2, -1, 3, 4, 5] }
            its(:'b.to_a') { is_expected.to eq ['x', 'y', 'x', 'a', 'y'] }
            its(:'c.to_a') { is_expected.to eq [nil, nil, -2, 2, 1] }
          end
        end
      end
    end
  end
end
