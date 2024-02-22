shared_examples_for 'a duplicatable DataFrame' do
  describe "#dup" do
    context DaruLite::Index do
      subject { df.dup }

      it "dups every data structure inside DataFrame" do
        expect(subject.object_id).not_to eq(df.object_id)
        expect(subject.vectors.object_id).not_to eq(df.vectors.object_id)
        expect(subject.index.object_id).not_to eq(df.index.object_id)

        df.each_vector_with_index do |vector, index|
          expect(vector.object_id).not_to eq(subject[index].object_id)
          expect(vector.to_a.object_id).not_to eq(subject[index].to_a.object_id)
        end
      end
    end

    context DaruLite::MultiIndex do
      subject { df_mi.dup }

      it "duplicates with multi index" do
        expect(subject).to eq(df_mi)
        expect(subject.vectors.object_id).not_to eq(df_mi.vectors.object_id)
        expect(subject.index.object_id).not_to eq(df_mi.index.object_id)
      end
    end
  end

  describe "#clone_structure" do
    subject { df.clone_structure }

    it "clones only the index and vector structures of the data frame" do
      expect(subject.vectors).to eq(df.vectors)
      expect(subject.index).to eq(df.index)
      expect(subject[:a]).to eq(DaruLite::Vector.new([nil] * subject[:a].size, index: df.index))
    end
  end

  describe "#clone" do
    subject { df.clone }

    context 'no argument is passed' do
      subject { df.clone }

      it "returns a view of the whole dataframe" do
        expect(df.object_id).to_not eq(subject.object_id)
        expect(df[:a].object_id).to eq(subject[:a].object_id)
        expect(df[:b].object_id).to eq(subject[:b].object_id)
        expect(df[:c].object_id).to eq(subject[:c].object_id)
      end
    end

    context 'vector names are passed' do
      subject { df.clone(:a, :b) }

      it "returns a view of selected vectors" do
        expect(subject.object_id).to_not eq(df.object_id)
        expect(subject[:a].object_id).to eq(df[:a].object_id)
        expect(subject[:b].object_id).to eq(df[:b].object_id)
      end
    end

    context 'array of vector names is passed' do
      subject { df.clone([:a, :b]) }

      it "clones properly when supplied array" do
        expect(subject.object_id).to_not eq(df.object_id)
        expect(subject[:a].object_id).to eq(df[:a].object_id)
        expect(subject[:b].object_id).to eq(df[:b].object_id)
      end
    end

    it "original dataframe remains unaffected when operations are applied on subject data frame" do
      original = df.dup
      subject.delete_vector :a

      expect(df).to eq(original)
    end
  end

  describe "#clone_only_valid" do
    subject { df.clone_only_valid }

    context 'df has missing values' do
      let(:df) do
        DaruLite::DataFrame.new({
          a: [1  , 2, 3, nil, 4, nil, 5],
          b: [nil, 2, 3, nil, 4, nil, 5],
          c: [1,   2, 3, 43 , 4, nil, 5]
        })
      end

      it 'clones only valid values' do
        expect(subject).to eq(df.reject_values(*DaruLite::MISSING_VALUES))
      end
    end

    context 'df has no missing values' do
      let(:df) do
        DaruLite::DataFrame.new({
          a: [2,3,4,5],
          c: [2,3,4,5]
        })
      end

      it 'clones all values' do
        expect(subject).to eq(df.clone)
      end
    end
  end
end
