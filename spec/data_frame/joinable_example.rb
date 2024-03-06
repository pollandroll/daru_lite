shared_examples_for 'a joinable DataFrame' do
  describe "#concat" do
    let(:df1) do
      DaruLite::DataFrame.new({
        a: [1, 2, 3],
        b: [1, 2, 3]
      })
    end
    let(:df2) do
      DaruLite::DataFrame.new({
        a: [4, 5, 6],
        c: [4, 5, 6]
      })
    end

    it 'does not modify the original dataframes' do
      df1_a = df1[:a].to_a.dup
      df2_a = df2[:a].to_a.dup

      df_concat = df1.concat df2
      expect(df1[:a].to_a).to eq df1_a
      expect(df2[:a].to_a).to eq df2_a
    end

    it 'creates a new dataframe that is a concatenation of the two dataframe arguments' do
      df1_a = df1[:a].to_a.dup
      df2_a = df2[:a].to_a.dup

      df_concat = df1.concat df2
      expect(df_concat[:a].to_a).to eq df1_a + df2_a
    end

    it 'fills in missing vectors with nils' do
      df1_b = df1[:b].to_a.dup
      df2_c = df2[:c].to_a.dup

      df_concat = df1.concat df2
      expect(df_concat[:b].to_a).to eq df1_b + [nil] * df2.size
      expect(df_concat[:c].to_a).to eq [nil] * df1.size + df2_c
    end
  end


  context "#union" do
    let(:df1) do
      DaruLite::DataFrame.new({
        a: [1, 2, 3],
        b: [1, 2, 3]},
        index: [1,3,5]
      )
    end
    let(:df2) do
      DaruLite::DataFrame.new({
        a: [4, 5, 6],
        c: [4, 5, 6]},
        index: [7,9,11]
      )
    end
    let(:df3) do
      DaruLite::DataFrame.new({
        a: [4, 5, 6],
        c: [4, 5, 6]},
        index: [5,7,9]
      )
    end

    it 'does not modify the original dataframes' do
      df1_a = df1[:a].to_a.dup
      df2_a = df2[:a].to_a.dup

      _ = df1.union df2
      expect(df1[:a].to_a).to eq df1_a
      expect(df2[:a].to_a).to eq df2_a
    end

    it 'creates a new dataframe that is a concatenation of the two dataframe arguments' do
      df1_a = df1[:a].to_a.dup
      df2_a = df2[:a].to_a.dup

      df_union = df1.union df2
      expect(df_union[:a].to_a).to eq df1_a + df2_a
    end

    it 'fills in missing vectors with nils' do
      df1_b = df1[:b].to_a.dup
      df2_c = df2[:c].to_a.dup

      df_union = df1.union df2
      expect(df_union[:b].to_a).to eq df1_b + [nil] * df2.size
      expect(df_union[:c].to_a).to eq [nil] * df1.size + df2_c
    end

    it 'overwrites part of the first dataframe if there are double indices' do
      vec = DaruLite::Vector.new({a: 4, b: nil, c: 4})
      expect(df1.union(df3).row[5]).to eq vec
    end

    it 'concats the indices' do
      v1 = df1.index.to_a
      v2 = df2.index.to_a

      df_union = df1.union df2
      expect(df_union.index.to_a).to eq v1 + v2
    end
  end
end
