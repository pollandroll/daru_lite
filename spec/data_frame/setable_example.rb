shared_examples_for 'a setable DataFrame' do
  describe "#row.set_at" do
    let(:df) do
      DaruLite::DataFrame.new({
        a: 1..3,
        b: 'a'..'c'
      })
    end

    context "single position" do
      subject { df }
      before { df.row.set_at [1], ['x', 'y'] }

      its(:size) { is_expected.to eq 3 }
      its(:'a.to_a') { is_expected.to eq [1, 'x', 3] }
      its(:'b.to_a') { is_expected.to eq ['a', 'y', 'c'] }
    end

    context "multiple position" do
      subject { df }
      before { df.row.set_at [0, 2], ['x', 'y'] }

      its(:size) { is_expected.to eq 3 }
      its(:'a.to_a') { is_expected.to eq ['x', 2, 'x'] }
      its(:'b.to_a') { is_expected.to eq ['y', 'b', 'y'] }
    end

    context "invalid position" do
      it { expect { df.row.set_at [3], ['x', 'y'] }.to raise_error IndexError }
    end

    context "invalid positions" do
      it { expect { df.row.set_at [2, 3], ['x', 'y'] }.to raise_error IndexError }
    end

    context "incorrect size" do
      it { expect { df.row.set_at [1], ['x', 'y', 'z'] }.to raise_error SizeError }
    end
  end

  describe "#set_at" do
    let(:df) do
      DaruLite::DataFrame.new({
        1 => 1..3,
        a: 'a'..'c',
        b: 11..13
      })
    end

    context "single position" do
      subject { df }
      before { df.set_at [1], ['x', 'y', 'z'] }

      its(:shape) { is_expected.to eq [3, 3] }
      it { expect(df[1].to_a).to eq [1, 2, 3] }
      its(:'a.to_a') { is_expected.to eq ['x', 'y', 'z'] }
      its(:'b.to_a') { is_expected.to eq [11, 12, 13] }
    end

    context "multiple position" do
      subject { df }
      before { df.set_at [1, 2], ['x', 'y', 'z'] }

      its(:shape) { is_expected.to eq [3, 3] }
      it { expect(df[1].to_a).to eq [1, 2, 3] }
      its(:'a.to_a') { is_expected.to eq ['x', 'y', 'z'] }
      its(:'b.to_a') { is_expected.to eq ['x', 'y', 'z'] }
    end

    context "invalid position" do
      it { expect { df.set_at [3], ['x', 'y', 'z'] }.to raise_error IndexError }
    end

    context "invalid positions" do
      it { expect { df.set_at [2, 3], ['x', 'y', 'z'] }.to raise_error IndexError }
    end

    context "incorrect size" do
      it { expect { df.set_at [1], ['x', 'y'] }.to raise_error SizeError }
    end
  end

  describe "#[]=" do
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

      it "assigns directly with the []= operator" do
        df[:a] = [100,200,300,400,500]
        expect(df).to eq(DaruLite::DataFrame.new({
          b: [11,12,13,14,15],
          a: [100,200,300,400,500],
          c: [11,22,33,44,55]}, order: [:a, :b, :c],
          index: [:one, :two, :three, :four, :five]))
      end

      it "assigns new vector with default length if given just a value" do
        df[:d] = 1.0
        expect(df[:d]).to eq(DaruLite::Vector.new([1.0, 1.0, 1.0, 1.0, 1.0],
        index: [:one, :two, :three, :four, :five], name: :d))
      end

      it "updates vector with default length if given just a value" do
        df[:c] = 1.0
        expect(df[:c]).to eq(DaruLite::Vector.new([1.0, 1.0, 1.0, 1.0, 1.0],
        index: [:one, :two, :three, :four, :five], name: :c))
      end

      it "appends an Array as a DaruLite::Vector" do
        df[:d] = [69,99,108,85,49]

        expect(df.d.class).to eq(DaruLite::Vector)
      end

      it "appends an arbitrary enumerable as a DaruLite::Vector" do
        df[:d] = Set.new([69,99,108,85,49])

        expect(df[:d]).to eq(DaruLite::Vector.new([69, 99, 108, 85, 49],
        index: [:one, :two, :three, :four, :five], name: :c))
      end

      it "replaces an already present vector" do
        df[:a] = [69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five])

        expect(df.a).to eq([69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five]))
      end

      it "appends a new vector to the DataFrame" do
        df[:woo] = [69,99,108,85,49].dv(nil, [:one, :two, :three, :four, :five])

        expect(df.vectors).to eq([:a, :b, :c, :woo].to_index)
      end

      it "creates an index for the new vector if not specified" do
        df[:woo] = [69,99,108,85,49]

        expect(df.woo.index).to eq([:one, :two, :three, :four, :five].to_index)
      end

      it "matches index of vector to be inserted with the DataFrame index" do
        df[:shankar] = [69,99,108,85,49].dv(:shankar, [:two, :one, :three, :five, :four])

        expect(df.shankar).to eq([99,69,108,49,85].dv(:shankar,
          [:one, :two, :three, :four, :five]))
      end

      it "matches index of vector to be inserted, inserting nils where no match found" do
        df[:shankar] = [1,2,3].dv(:shankar, [:one, :james, :hetfield])

        expect(df.shankar).to eq([1,nil,nil,nil,nil].dv(:shankar, [:one, :two, :three, :four, :five]))
      end

      it "raises error for Array assignment of wrong length" do
        expect{
          df[:shiva] = [1,2,3]
          }.to raise_error
      end

      it "assigns correct name given empty dataframe" do
        df_empty = DaruLite::DataFrame.new({})
        df_empty[:a] = 1..5
        df_empty[:b] = 1..5

        expect(df_empty[:a].name).to equal(:a)
        expect(df_empty[:b].name).to equal(:b)
      end

      it "appends multiple vectors at a time" do
        # TODO
      end
    end

    context DaruLite::MultiIndex do
      it "raises error when incomplete index specified but index is absent" do
        expect {
          df_mi[:d] = [100,200,300,400,100,200,300,400,100,200,300,400]
        }.to raise_error
      end

      it "assigns all sub-indexes when a top level index is specified" do
        df_mi[:a] = [100,200,300,400,100,200,300,400,100,200,300,400]

        expect(df_mi).to eq(DaruLite::DataFrame.new([
          [100,200,300,400,100,200,300,400,100,200,300,400],
          [100,200,300,400,100,200,300,400,100,200,300,400],
          vector_arry1,
          vector_arry2], index: multi_index, order: order_mi))
      end

      it "creates a new vector when full index specfied" do
        order = DaruLite::MultiIndex.from_tuples([
          [:a,:one,:bar],
          [:a,:two,:baz],
          [:b,:two,:foo],
          [:b,:one,:foo],
          [:c,:one,:bar]])
        answer = DaruLite::DataFrame.new([
          vector_arry1,
          vector_arry2,
          vector_arry1,
          vector_arry2,
          [100,200,300,400,100,200,300,400,100,200,300,400]
          ], index: multi_index, order: order)
        df_mi[:c,:one,:bar] = [100,200,300,400,100,200,300,400,100,200,300,400]

        expect(df_mi).to eq(answer)
      end

      it "assigns correct name given empty dataframe" do
        df_empty = DaruLite::DataFrame.new([], index: multi_index, order: order_mi)
        df_empty[:c, :one, :bar] = 1..12

        expect(df_empty[:c, :one, :bar].name).to eq "conebar"
      end
    end
  end

  describe "#add_row" do
    subject(:data_frame) {
      DaruLite::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
        c: [11,22,33,44,55]}, order: [:a, :b, :c],
        index: [:one, :two, :three, :four, :five])
    }
    context 'named' do
      before {
        data_frame.add_row [100,200,300], :six
      }

      it { is_expected.to eq(DaruLite::DataFrame.new({
            a: [1,2,3,4,5,100],
            b: [11,12,13,14,15,200],
            c: [11,22,33,44,55,300]}, order: [:a, :b, :c],
            index: [:one, :two, :three, :four, :five, :six]))
      }
    end

    context 'unnamed' do
      before {
        data_frame.add_row [100,200,300]
      }

      it { is_expected.to eq(DaruLite::DataFrame.new({
            a: [1,2,3,4,5,100],
            b: [11,12,13,14,15,200],
            c: [11,22,33,44,55,300]}, order: [:a, :b, :c],
            index: [:one, :two, :three, :four, :five, 5]))
      }
    end

    context 'with mulitiindex DF' do
      subject(:data_frame) do
        DaruLite::DataFrame.new({b: [11,12,13], a: [1,2,3],
          c: [11,22,33]}, order: [:a, :b, :c],
          index: DaruLite::MultiIndex.from_tuples([[:one, :two], [:one, :three], [:two, :four]]))
      end

      before { data_frame.add_row [100,200,300], [:two, :five] }

      it { is_expected.to eq(DaruLite::DataFrame.new({
          b: [11,12,13,200], a: [1,2,3,100],
          c: [11,22,33,300]}, order: [:a, :b, :c],
          index: DaruLite::MultiIndex.from_tuples([[:one, :two], [:one, :three], [:two, :four], [:two, :five]])))
      }
    end

    it "allows adding rows after making empty DF by specfying only order" do
      df = DaruLite::DataFrame.new({}, order: [:a, :b, :c])
      df.add_row [1,2,3]
      df.add_row [5,6,7]

      expect(df[:a]).to eq(DaruLite::Vector.new([1,5]))
      expect(df[:b]).to eq(DaruLite::Vector.new([2,6]))
      expect(df[:c]).to eq(DaruLite::Vector.new([3,7]))
      expect(df.index).to eq(DaruLite::Index.new([0,1]))
    end
  end

  describe '#add_vector' do
    subject(:data_frame) do
      DaruLite::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
        c: [11,22,33,44,55]}, order: [:a, :b, :c],
        index: [:one, :two, :three, :four, :five])
    end

    before { data_frame.add_vector :a, [100,200,300,400,500] }

    it { is_expected.to eq(DaruLite::DataFrame.new({
          b: [11,12,13,14,15],
          a: [100,200,300,400,500],
          c: [11,22,33,44,55]}, order: [:a, :b, :c],
          index: [:one, :two, :three, :four, :five]))
    }
  end

  describe "#insert_vector" do
    subject(:data_frame) do
      DaruLite::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
        c: [11,22,33,44,55]}, order: [:a, :b, :c],
        index: [:one, :two, :three, :four, :five])
    end

    it "insert a new vector at the desired slot" do
      df = DaruLite::DataFrame.new({
        a: [1,2,3,4,5],
        d: [710, 720, 730, 740, 750],
        b: [11, 12, 13, 14, 15],
        c: [11,22,33,44,55]}, order: [:a, :d, :b, :c],
        index: [:one, :two, :three, :four, :five]
      )
      data_frame.insert_vector 1, :d, [710, 720, 730, 740, 750]
      expect(subject).to eq df
    end

    it "raises error for data array being too big" do
      expect {
        source = (1..8).to_a
        data_frame.insert_vector 1, :d, source
      }.to raise_error(IndexError)
    end

    it "raises error for invalid index value" do
      expect {
        source = (1..5).to_a
        data_frame.insert_vector 4, :d, source
      }.to raise_error(ArgumentError)
    end

    it "raises error for invalid source type" do
      expect {
        source = 14
        data_frame.insert_vector 3, :d, source
      }.to raise_error(ArgumentError)
    end
  end

  describe "#row[]=" do
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

      it "assigns specified row when Array" do
        df.row[:one] = [49, 99, 59]

        expect(df.row[:one])      .to eq([49, 99, 59].dv(:one, [:a, :b, :c]))
        expect(df.row[:one].index).to eq([:a, :b, :c].to_index)
        expect(df.row[:one].name) .to eq(:one)
      end

      it "assigns specified row when DV" do
        df.row[:one] = [49, 99, 59].dv(nil, [:a, :b, :c])

        expect(df.row[:one]).to eq([49, 99, 59].dv(:one, [:a, :b, :c]))
      end

      it "assigns correct elements when Vector of different index" do
        df.row[:one] = DaruLite::Vector.new([44,62,11], index: [:b,:f,:a])

        expect(df.row[:one]).to eq(DaruLite::Vector.new([11,44,nil], index: [:a,:b,:c]))
      end

      it "creates a new row from an Array" do
        df.row[:patekar] = [9,2,11]

        expect(df.row[:patekar]).to eq([9,2,11].dv(:patekar, [:a, :b, :c]))
      end

      it "creates a new row from a DV" do
        df.row[:patekar] = [9,2,11].dv(nil, [:a, :b, :c])

        expect(df.row[:patekar]).to eq([9,2,11].dv(:patekar, [:a, :b, :c]))
      end

      it "creates a new row from numeric row index and named DV" do
        df.row[2] = [9,2,11].dv(nil, [:a, :b, :c])

        expect(df.row[2]).to eq([9,2,11].dv(nil, [:a, :b, :c]))
      end

      it "correctly aligns assigned DV by index" do
        df.row[:two] = [9,2,11].dv(nil, [:b, :a, :c])

        expect(df.row[:two]).to eq([2,9,11].dv(:two, [:a, :b, :c]))
      end

      it "correctlu aligns assinged DV by index for new rows" do
        df.row[:latest] = DaruLite::Vector.new([2,3,1], index: [:b,:c,:a])

        expect(df.row[:latest]).to eq(DaruLite::Vector.new([1,2,3], index: [:a,:b,:c]))
      end

      it "inserts nils for indexes that dont exist in the DataFrame" do
        df.row[:two] = [49, 99, 59].dv(nil, [:oo, :aah, :gaah])

        expect(df.row[:two]).to eq([nil,nil,nil].dv(nil, [:a, :b, :c]))
      end

      it "correctly inserts row of a different length by matching indexes" do
        df.row[:four] = [5,4,3,2,1,3].dv(nil, [:you, :have, :a, :big, :appetite, :spock])

        expect(df.row[:four]).to eq([3,nil,nil].dv(:four, [:a, :b, :c]))
      end

      it "raises error for row insertion by Array of wrong length" do
        expect{
          df.row[:one] = [1,2,3,4,5,6,7]
        }.to raise_error
      end
    end

    context DaruLite::MultiIndex do
      pending
      # TO DO
    end

    context DaruLite::CategoricalIndex do
      let(:idx) { DaruLite::CategoricalIndex.new [:a, 1, :a, 1, :c] }
      let(:df) do
        DaruLite::DataFrame.new({
          a: 'a'..'e',
          b: 1..5
        }, index: idx)
      end

      context "modify exiting row" do
        context "single category" do
          subject { df }
          before { df.row[:a] = ['x', 'y'] }

          it { is_expected.to be_a DaruLite::DataFrame }
          its(:index) { is_expected.to eq idx }
          its(:vectors) { is_expected.to eq DaruLite::Index.new [:a, :b] }
          its(:'a.to_a') { is_expected.to eq ['x', 'b', 'x', 'd', 'e'] }
          its(:'b.to_a') { is_expected.to eq ['y', 2, 'y', 4, 5] }
        end

        context "multiple categories" do
          subject { df }
          before { df.row[:a, 1] = ['x', 'y'] }

          it { is_expected.to be_a DaruLite::DataFrame }
          its(:index) { is_expected.to eq idx }
          its(:vectors) { is_expected.to eq DaruLite::Index.new [:a, :b] }
          its(:'a.to_a') { is_expected.to eq ['x', 'x', 'x', 'x', 'e'] }
          its(:'b.to_a') { is_expected.to eq ['y', 'y', 'y', 'y', 5] }
        end

        context "positional index" do
          subject { df }
          before { df.row[0, 2] = ['x', 'y'] }

          it { is_expected.to be_a DaruLite::DataFrame }
          its(:index) { is_expected.to eq idx }
          its(:vectors) { is_expected.to eq DaruLite::Index.new [:a, :b] }
          its(:'a.to_a') { is_expected.to eq ['x', 'b', 'x', 'd', 'e'] }
          its(:'b.to_a') { is_expected.to eq ['y', 2, 'y', 4, 5] }
        end
      end

      context "add new row" do
        # TODO
      end
    end
  end
end
