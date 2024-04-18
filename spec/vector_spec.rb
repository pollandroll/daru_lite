require 'spec_helper.rb'
require 'vector/aggregatable_example'
require 'vector/calculatable_example'
require 'vector/convertible_example'
require 'vector/duplicatable_example'
require 'vector/fetchable_example'
require 'vector/filterable_example'
require 'vector/indexable_example'
require 'vector/iterable_example'
require 'vector/joinable_example'
require 'vector/missable_example'
require 'vector/queryable_example'
require 'vector/setable_example'
require 'vector/sortable_example'

describe DaruLite::Vector do
  ALL_DTYPES.each do |dtype|
    describe dtype.to_s do
      describe "#initialize" do
        let(:multi_index) do
          tuples = [
            [:a, :one, :foo],
            [:a, :two, :bar],
            [:b, :one, :bar],
            [:b, :two, :baz]
          ]
          DaruLite::MultiIndex.from_tuples(tuples)
        end

        it "initializes from an Array" do
          dv = DaruLite::Vector.new(
            [1, 2, 3, 4, 5],
            name: :ravan,
            index: [:ek, :don, :teen, :char, :pach],
            dtype:
          )

          expect(dv.name) .to eq(:ravan)
          expect(dv.index).to eq(DaruLite::Index.new([:ek, :don, :teen, :char, :pach]))
        end

        it "accepts Index object" do
          idx = DaruLite::Index.new [:yoda, :anakin, :obi, :padme, :r2d2]
          dv = DaruLite::Vector.new([1,2,3,4,5], name: :yoga, index: idx, dtype:)

          expect(dv.name) .to eq(:yoga)
          expect(dv.index).to eq(idx)
        end

        it "accepts a MultiIndex object" do
          dv = DaruLite::Vector.new([1,2,3,4], name: :mi, index: multi_index, dtype:)

          expect(dv.name).to eq(:mi)
          expect(dv.index).to eq(multi_index)
        end

        it "raises error for improper Index" do
          expect {
            dv = DaruLite::Vector.new [1, 2, 3, 4, 5], name: :yoga, index: [:i, :j, :k]
          }.to raise_error

          expect {
            idx = DaruLite::Index.new([:i, :j, :k])
            dv  = DaruLite::Vector.new([1, 2, 3, 4, 5], name: :yoda, index: idx, dtype:)
          }.to raise_error
        end

        it "raises error for improper MultiIndex" do
          expect {
            dv = DaruLite::Vector.new([1, 2, 3, 4, 5], name: :mi, index: multi_index)
          }.to raise_error
        end

        it "initializes without specifying an index" do
          dv = DaruLite::Vector.new([1, 2, 3, 4, 5], name: :vishnu, dtype:)

          expect(dv.index).to eq(DaruLite::Index.new([0, 1, 2, 3, 4]))
        end

        it "inserts nils for extra indices" do
          dv = DaruLite::Vector.new([1, 2, 3], name: :yoga, index: [0, 1, 2, 3, 4], dtype:)

          expect(dv).to eq([1, 2, 3, nil, nil].dv(:yoga,nil, :array))
        end

        it "inserts nils for extra indices (MultiIndex)" do
          dv = DaruLite::Vector.new [1, 2], name: :mi, index: multi_index, dtype: :array
          expect(dv).to eq(DaruLite::Vector.new([1, 2, nil, nil], name: :mi, index: multi_index, dtype: :array))
        end

        it "accepts all sorts of objects for indexing" do
          dv = DaruLite::Vector.new([1, 2, 3, 4], index: ['a', 'b', :r, 0])
          expect(dv.to_a).to eq([1, 2, 3, 4])
          expect(dv.index.to_a).to eq(['a', 'b', :r, 0])
        end
      end

      describe ".new_with_size" do
        it "creates new vector from only size" do
          v1 = DaruLite::Vector.new(10.times.map { nil }, dtype:)
          v2 = DaruLite::Vector.new_with_size(10, dtype:)
          expect(v2).to eq(v1)
        end if dtype == :array

        it "creates new vector from only size and value" do
          a = rand
          v1 = DaruLite::Vector.new(10.times.map { a }, dtype:)
          v2 = DaruLite::Vector.new_with_size(10, value: a, dtype:)
          expect(v2).to eq(v1)
        end

        it "accepts block" do
          v1 = DaruLite::Vector.new 10.times.map {|i| i * 2 }
          v2 = DaruLite::Vector.new_with_size(10, dtype:) { |i| i * 2 }
          expect(v2).to eq(v1)
        end
      end

      describe ".[]" do
        it "returns same results as R-c()" do
          reference = DaruLite::Vector.new([0, 4, 5, 6, 10])
          expect(DaruLite::Vector[0, 4, 5, 6, 10])          .to eq(reference)
          expect(DaruLite::Vector[0, 4..6, 10])             .to eq(reference)
          expect(DaruLite::Vector[[0], [4, 5, 6], [10]])    .to eq(reference)
          expect(DaruLite::Vector[[0], [4, [5, [6]]], [10]]).to eq(reference)

          expect(DaruLite::Vector[[0], DaruLite::Vector.new([4, 5, 6]), [10]])
                                                        .to eq(reference)
        end
      end

      context "#==" do
        subject { vector == other_vector }

        let(:vector) { DaruLite::Vector.new(data, name:, index:, dtype:) }
        let(:data) { [1, 2, 3, 4, 5] }
        let(:index) { [:yoda, :anakin, :obi, :padme, :r2d2] }
        let(:name) { :yoga }
        let(:other_vector) { DaruLite::Vector.new(other_data, name: other_name, index: other_index, dtype:) }
        let(:other_data) { data }
        let(:other_index) { index }
        let(:other_name) { name }

        context DaruLite::Index do

          context 'vectors are identical' do
            it { is_expected.to eq(true) }
          end

          context 'name is different' do
            let(:other_name) { :yogi }

            it { is_expected.to eq(true) }
          end

          context 'data is different' do
            let(:other_data) { [2, 1, 3, 4, 5] }

            it { is_expected.to eq(false) }
          end

          context 'data size is different' do
            let(:other_data) { [1, 2, 3, 4, 5, 6] }
            let(:other_index) { [:yoda, :anakin, :obi, :padme, :r2d2, :darth_vader] }

            it { is_expected.to eq(false) }
          end

          context 'vector index is different' do
            let(:other_index) { [:anakin, :yoda, :darth_vader, :padme, :r2d2] }

            it { is_expected.to eq(false) }
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
          let(:data) { Array.new(12) { |i| i } }
          let(:index) { DaruLite::MultiIndex.from_tuples(tuples) }

          context 'vectors are identical' do
            it { is_expected.to eq(true) }
          end

          context 'name is different' do
            let(:other_name) { :yogi }

            it { is_expected.to eq(true) }
          end

          context 'data is different' do
            let(:other_data) { Array.new(12) { |i| i * i } }

            it { is_expected.to eq(false) }
          end

          context 'data size is different' do
            let(:other_data) { Array.new(10) { |i| i * i } }

            it { is_expected.to eq(false) }
          end

          context 'vector index is different' do
            let(:other_tuples) do
              [
                [:a,:two,:bar],
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
            let(:other_index) { DaruLite::MultiIndex.from_tuples(other_tuples) }

            it { is_expected.to eq(false) }
          end
        end

        context DaruLite::CategoricalIndex do
          let(:index) { DaruLite::CategoricalIndex.new([:yoda, :r2d2, :obi, :padme, :r2d2]) }

          context 'vectors are identical' do
            it { is_expected.to eq(true) }
          end

          context 'name is different' do
            let(:other_name) { :yogi }

            it { is_expected.to eq(true) }
          end

          context 'data is different' do
            let(:other_data) { [2, 1, 3, 4, 5] }

            it { is_expected.to eq(false) }
          end

          context 'data size is different' do
            let(:other_data) { [1, 2, 3, 4, 5, 6] }
            let(:other_index) { [:yoda, :anakin, :obi, :padme, :r2d2, :darth_vader] }

            it { is_expected.to eq(false) }
          end

          context 'vector index is different' do
            let(:other_index) { DaruLite::CategoricalIndex.new([:r2d2, :yoda, :obi, :padme, :r2d2]) }

            it { is_expected.to eq(false) }
          end
        end
      end

      context "#delete" do
        context DaruLite::Index do
          it "deletes specified value in the vector" do
            dv = DaruLite::Vector.new [1,2,3,4,5], name: :a, dtype: dtype

            dv.delete 3
            expect(dv).to eq(
              DaruLite::Vector.new [1,2,4,5], name: :a, index: [0,1,3,4])
          end
        end
      end

      context "#delete_at" do
        context DaruLite::Index do
          before :each do
            @dv = DaruLite::Vector.new [1,2,3,4,5], name: :a,
              index: [:one, :two, :three, :four, :five], dtype: dtype
          end

          it "deletes element of specified index" do
            @dv.delete_at :one

            expect(@dv).to eq(DaruLite::Vector.new [2,3,4,5], name: :a,
              index: [:two, :three, :four, :five], dtype: dtype)
          end

          it "deletes element of specified integer index" do
            pending
            @dv.delete_at 2

            expect(@dv).to eq(DaruLite::Vector.new [1,2,4,5], name: :a,
              index: [:one, :two, :four, :five], dtype: dtype)
          end
        end
      end

      context "#cast" do
        ALL_DTYPES.each do |new_dtype|
          it "casts from #{dtype} to #{new_dtype}" do
            v = DaruLite::Vector.new [1,2,3,4], dtype: dtype
            v.cast(dtype: new_dtype)
            expect(v.dtype).to eq(new_dtype)
          end
        end
      end

      context "#bootstrap" do
        it "returns a vector with mean=mu and sd=se" do
          rng = Distribution::Normal.rng(0, 1)
          vector =DaruLite::Vector.new_with_size(100, dtype:) { rng.call}

          df = vector.bootstrap([:mean, :sd], 200)
          se = 1 / Math.sqrt(vector.size)
          expect(df[:mean].mean).to be_within(0.3).of(0)
          expect(df[:mean].sd).to be_within(0.02).of(se)
        end
      end

      it_behaves_like 'a calculatable Vector', dtype
      it_behaves_like 'a convertible Vector', dtype
      it_behaves_like 'a fetchable Vector', dtype
      it_behaves_like 'a filterable Vector', dtype
      it_behaves_like 'an indexable Vector', dtype
      it_behaves_like 'an iterable Vector', dtype
      it_behaves_like 'a joinable Vector', dtype
      it_behaves_like 'a setable Vector', dtype
      it_behaves_like 'a sortable Vector', dtype
    end
  end # describe ALL_DTYPES.each

  # -----------------------------------------------------------------------
  # works with arrays only

  it_behaves_like 'an aggregatable Vector'
  it_behaves_like 'a duplicatable Vector'
  it_behaves_like 'a missable Vector'
  it_behaves_like 'a queryable Vector'

  context "#splitted" do
    it "splits correctly" do
      a = DaruLite::Vector.new ['a', 'a,b', 'c,d', 'a,d', 'd', 10, nil]
      expect(a.splitted).to eq([%w(a), %w(a b), %w(c d), %w(a d), %w(d), [10], nil])
    end
  end

  context '#is_values' do
    let(:dv) { DaruLite::Vector.new [10, 11, 10, nil, nil] }

    context 'single value' do
      subject { dv.is_values 10 }
      it { is_expected.to be_a DaruLite::Vector }
      its(:to_a) { is_expected.to eq [true, false, true, false, false] }
    end

    context 'multiple values' do
      subject { dv.is_values 10, nil }
      it { is_expected.to be_a DaruLite::Vector }
      its(:to_a) { is_expected.to eq [true, false, true, true, true] }
    end
  end

  describe "#type" do
    before(:each) do
      @numeric    = DaruLite::Vector.new([1,2,3,4,5])
      @multi      = DaruLite::Vector.new([1,2,3,'sameer','d'])
      @with_nils  = DaruLite::Vector.new([1,2,3,4,nil])
    end

    it "checks numeric data correctly" do
      expect(@numeric.type).to eq(:numeric)
    end

    it "checks for multiple types of data" do
      expect(@multi.type).to eq(:object)
    end

    it "changes type to object as per assignment" do
      expect(@numeric.type).to eq(:numeric)
      @numeric[2] = 'my string'
      expect(@numeric.type).to eq(:object)
    end

    it "changes type to numeric as per assignment" do
      expect(@multi.type).to eq(:object)
      @multi[3] = 45
      @multi[4] = 54
      expect(@multi.type).to eq(:numeric)
    end

    it "reports numeric if nils with number data" do
      expect(@with_nils.type).to eq(:numeric)
    end

    it "stays numeric when nil is reassigned to a number" do
      @with_nils[4] = 66
      expect(@with_nils.type).to eq(:numeric)
    end

    it "changes to :object when nil is reassigned to anything but a number" do
      @with_nils[4] = 'string'
      expect(@with_nils.type).to eq(:object)
    end
  end

  describe "#split_by_separator" do
    subject { vector.split_by_separator(separator) }

    let(:vector) { DaruLite::Vector.new ['a', 'a,b', 'c,d', 'a,d', 10, nil] }
    let(:separator) { ',' }

    def expect_correct_tokens(hash)
      expect(hash['a'].to_a).to eq([1, 1, 0, 1, 0, nil])
      expect(hash['b'].to_a).to eq([0, 1, 0, 0, 0, nil])
      expect(hash['c'].to_a).to eq([0, 0, 1, 0, 0, nil])
      expect(hash['d'].to_a).to eq([0, 0, 1, 1, 0, nil])
      expect(hash[10].to_a).to eq([0, 0, 0, 0, 1, nil])
    end

    it "returns a Hash" do
      expect(subject.class).to eq(Hash)
    end

    it "returned Hash has keys with with different values of a" do
      expect(subject.keys).to eq(['a', 'b', 'c', 'd', 10])
    end

    it "returns a Hash, whose values are DaruLite::Vector" do
      subject.each_key do |key|
        expect(subject[key].class).to eq(DaruLite::Vector)
      end
    end

    it "ensures that hash values are n times the tokens appears" do
      expect_correct_tokens subject
    end

    context 'when using a different separator' do
      let(:vector) { DaruLite::Vector.new ['a', 'a*b', 'c*d', 'a*d', 10, nil] }
      let(:separator) { '*' }

      it "gives the same values using a different separator" do
        expect_correct_tokens subject
      end
    end
  end

  describe "#split_by_separator_freq" do
    subject { vector.split_by_separator_freq }

    let(:vector) { DaruLite::Vector.new ['a', 'a,b', 'c,d', 'a,d', 10, nil] }

    it "returns the number of ocurrences of tokens" do
      expect(subject).to eq(
        { 'a' => 3, 'b' => 1, 'c' => 1, 'd' => 2, 10 => 1 }
      )
    end
  end

  describe "#rename" do
    let(:vector) { DaruLite::Vector.new [1, 2, 3, 4, 5, 5], name: :this_vector }

    it "assings name" do
      vector.rename :that_vector
      expect(vector.name).to eq(:that_vector)
    end

    it "stores name as a symbol" do
      vector.rename "This is a vector"
      expect(vector.name).to eq("This is a vector")
    end

    it "returns vector" do
      expect(vector.rename 'hello').to be_a DaruLite::Vector
    end
  end

  describe '#lag' do
    let(:source) { DaruLite::Vector.new(1..5) }

    context 'by default' do
      subject { source.lag }
      it { is_expected.to eq DaruLite::Vector.new([nil, 1, 2, 3, 4]) }
    end

    subject { source.lag(amount) }

    context '0' do
      let(:amount) { 0 }
      it { is_expected.to eq DaruLite::Vector.new([1, 2, 3, 4, 5]) }
    end

    context 'same as vector size' do
      let(:amount) { source.size }
      it { is_expected.to eq DaruLite::Vector.new([nil]*source.size) }
    end

    context 'same as vector -ve size' do
      let(:amount) { -source.size }
      it { is_expected.to eq DaruLite::Vector.new([nil]*source.size) }
    end

    context 'positive' do
      let(:amount) { 2 }
      it { is_expected.to eq DaruLite::Vector.new([nil, nil, 1, 2, 3]) }
    end

    context 'negative' do
      let(:amount) { -1 }
      it { is_expected.to eq DaruLite::Vector.new([2, 3, 4, 5, nil]) }
    end

    context 'large positive' do
      let(:amount) { source.size + 100 }
      it { is_expected.to eq DaruLite::Vector.new([nil]*source.size) }
    end

    context 'large negative' do
      let(:amount) { -(source.size + 100) }
      it { is_expected.to eq DaruLite::Vector.new([nil]*source.size) }
    end
  end

  describe '#method_missing' do
    context 'getting' do
      subject(:vector) { DaruLite::Vector.new [1,2,3], index: [:a, :b, :c] }

      it 'returns value for existing index' do
        expect(vector.a).to eq 1
      end

      it 'raises on getting non-existent index' do
        expect { vector.d }.to raise_error NoMethodError
      end

      it 'sets existing index' do
        vector.a = 5
        expect(vector[:a]).to eq 5
      end

      it 'raises on non-existent index setting' do
        # FIXME: inconsistency between IndexError here and NoMethodError on getting - zverok
        expect { vector.d = 5 }.to raise_error IndexError
      end
    end
  end

  describe '#db_type' do
    it 'is DATE for vector with any date in it' do
      # FIXME: is it sane?.. - zverok
      expect(DaruLite::Vector.new(['2016-03-01', 'foo', 4]).db_type).to eq 'DATE'
    end

    it 'is INTEGER for digits-only values' do
      expect(DaruLite::Vector.new(['123', 456, 789]).db_type).to eq 'INTEGER'
    end

    it 'is DOUBLE for digits-and-point values' do
      expect(DaruLite::Vector.new(['123.4', 456, 789e-10]).db_type).to eq 'DOUBLE'
    end

    it 'is VARCHAR for everyting else' do
      expect(DaruLite::Vector.new(['123 and stuff', 456, 789e-10]).db_type).to eq 'VARCHAR (255)'
    end
  end

  context 'on wrong dtypes' do
    it 'should not accept mdarray' do
      expect { DaruLite::Vector.new([], dtype: :mdarray) }.to raise_error(NotImplementedError)
    end

    it 'should not accept anything else' do
      expect { DaruLite::Vector.new([], dtype: :kittens) }.to raise_error(ArgumentError)
    end
  end

  context '#where clause when Nan, nil data value is present' do
    let(:v) { DaruLite::Vector.new([1,2,3,Float::NAN, nil]) }

    it 'missing/undefined data in Vector/DataFrame' do
      expect(v.where(v.lt(4))).to eq(DaruLite::Vector.new([1,2,3]))
      expect(v.where(v.lt(3))).to eq(DaruLite::Vector.new([1,2]))
      expect(v.where(v.lt(2))).to eq(DaruLite::Vector.new([1]))
    end
  end
end if mri?
