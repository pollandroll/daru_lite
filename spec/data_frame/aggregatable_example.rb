shared_examples_for 'an aggregatable DataFrame' do
  describe "#group_by" do
    context "on a single row DataFrame" do
      subject { df.group_by([:city]) }

      let(:df){ DaruLite::DataFrame.new(city: %w[Kyiv], year: [2015], value: [1]) }

      it "returns a groupby object" do
        expect(subject).to be_a(DaruLite::Core::GroupBy)
      end

      it "has the correct index" do
        expect(subject.groups).to eq({["Kyiv"]=>[0]})
      end
    end
  end

  describe '#aggregate' do
    let(:cat_idx) { DaruLite::CategoricalIndex.new [:a, :b, :a, :a, :c] }
    let(:df) { DaruLite::DataFrame.new(num: [52,12,07,17,01], cat_index: cat_idx) }
    let(:df_cat_idx) do
      DaruLite::DataFrame.new({num: [52,12,07,17,01]}, index: cat_idx)
    end

    it 'lambda function on particular column' do
      expect(df.aggregate(num_100_times: ->(df) { (df.num*100).first })).to eq(
          DaruLite::DataFrame.new(num_100_times: [5200, 1200, 700, 1700, 100])
        )
    end

    it 'aggregate sum on particular column' do
      expect(df_cat_idx.aggregate(num: :sum)).to eq(
          DaruLite::DataFrame.new({num: [76, 12, 1]}, index: [:a, :b, :c])
        )
    end
  end

  describe '#group_by_and_aggregate' do
    let(:spending_df) do
      DaruLite::DataFrame.rows([
        [2010,    'dev',  50, 1],
        [2010,    'dev', 150, 1],
        [2010,    'dev', 200, 1],
        [2011,    'dev',  50, 1],
        [2012,    'dev', 150, 1],

        [2011, 'office', 300, 1],

        [2010, 'market',  50, 1],
        [2011, 'market', 500, 1],
        [2012, 'market', 500, 1],
        [2012, 'market', 300, 1],

        [2012,    'R&D',  10, 1],],
        order: [:year, :category, :spending, :nb_spending])
    end

    it 'works as group_by + aggregate' do
      expect(spending_df.group_by_and_aggregate(:year, spending: :sum)).to eq(
        spending_df.group_by(:year).aggregate(spending: :sum))
      expect(spending_df.group_by_and_aggregate([:year, :category], spending: :sum, nb_spending: :size)).to eq(
        spending_df.group_by([:year, :category]).aggregate(spending: :sum, nb_spending: :size))
    end
  end
end
