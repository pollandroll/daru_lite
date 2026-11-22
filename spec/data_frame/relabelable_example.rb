shared_examples_for 'a relabelable DataFrame' do
  describe '#symbolize_vectors!' do
    subject { df.symbolize_vectors! }

    let(:df) { DaruLite::DataFrame.new({ 'a' => [1, 2], 'b' => [3, 4] }) }

    it { is_expected.to equal(df) }
    its('vectors.to_a') { is_expected.to eq(%i[a b]) }

    it 'names each vector after its symbolized label' do
      expect(subject[:b].name).to eq(:b)
    end

    it 'keeps the data' do
      expect(subject[:b].to_a).to eq([3, 4])
    end

    context 'with MultiIndex vectors' do
      let(:df) do
        DaruLite::DataFrame.new(
          [[1, 2], [3, 4]],
          order: DaruLite::MultiIndex.from_tuples([%w[a x], %w[b y]])
        )
      end

      its(:vectors) { is_expected.to eq(DaruLite::MultiIndex.from_tuples([%i[a x], %i[b y]])) }
    end

    context 'when the vectors index is named' do
      before { df.vectors.name = 'columns' }

      its('vectors.name') { is_expected.to eq('columns') }
    end

    context 'with vector names that are not Strings' do
      let(:df) { DaruLite::DataFrame.new({ 0 => [1, 2], nil => [3, 4], 'c' => [5, 6] }) }

      its('vectors.to_a') { is_expected.to eq([0, nil, :c]) }
    end

    context 'when two vectors would get the same name' do
      let(:df) { DaruLite::DataFrame.new({ 'a' => [1, 2], a: [3, 4] }) }

      it { expect { subject }.to raise_error(ArgumentError, 'Labels must be unique, got duplicates: :a') }

      it 'leaves the vectors untouched' do
        expect { subject rescue ArgumentError }.not_to(change { df.vectors.to_a })
      end
    end
  end

  describe '#rename_blank_vectors!' do
    subject { df.rename_blank_vectors!(:none) }

    let(:df) { DaruLite::DataFrame.new({ blank_name => [1, 2], b: [3, 4] }) }
    let(:blank_name) { nil }

    it { is_expected.to equal(df) }
    its('vectors.to_a') { is_expected.to eq(%i[none b]) }

    it 'keeps the data of the renamed vector' do
      expect(subject[:none].to_a).to eq([1, 2])
    end

    ['', '  ', :'  ', false].each do |name|
      context "with a vector named #{name.inspect}" do
        let(:blank_name) { name }

        its('vectors.to_a') { is_expected.to eq(%i[none b]) }
      end
    end

    context 'when the vectors index is named' do
      before { df.vectors.name = 'columns' }

      its('vectors.name') { is_expected.to eq('columns') }
    end

    ['', nil].each do |blank|
      context "when the label is #{blank.inspect}" do
        subject { df.rename_blank_vectors!(blank) }

        it { expect { subject }.to raise_error(ArgumentError, 'label must not be blank') }
      end
    end

    context 'without blank vector names' do
      let(:blank_name) { :a }

      its('vectors.to_a') { is_expected.to eq(%i[a b]) }
    end

    context 'with several blank vectors' do
      let(:df) { DaruLite::DataFrame.new({ nil => [1, 2], b: [3, 4], '' => [5, 6] }) }

      its('vectors.to_a') { is_expected.to eq(%i[none b] + [:'none (1)']) }

      it 'keeps the data of each renamed vector' do
        expect(subject[:'none (1)'].to_a).to eq([5, 6])
      end
    end

    context 'when a vector already has the label' do
      let(:df) { DaruLite::DataFrame.new({ nil => [1, 2], none: [3, 4] }) }

      its('vectors.to_a') { is_expected.to eq([:'none (1)', :none]) }

      it 'keeps that vector under the label' do
        expect(subject[:none].to_a).to eq([3, 4])
      end
    end

    context 'with a String label' do
      subject { df.rename_blank_vectors!('none') }

      let(:df) { DaruLite::DataFrame.new({ nil => [1, 2], '' => [3, 4] }) }

      its('vectors.to_a') { is_expected.to eq(['none', 'none (1)']) }
    end

    context 'with MultiIndex vectors' do
      let(:df) do
        DaruLite::DataFrame.new([[1, 2], [3, 4]], order: DaruLite::MultiIndex.from_tuples([['', :x], [:b, :y]]))
      end

      it { expect { subject }.to raise_error(NotImplementedError) }
    end
  end

  describe '#rename_blank_rows!' do
    subject { df.rename_blank_rows!('none') }

    let(:df) { DaruLite::DataFrame.new({ a: [1, 2, 3] }, index:) }
    let(:index) { [nil, '', 'x'] }

    it { is_expected.to equal(df) }
    its('index.to_a') { is_expected.to eq(['none', 'none (1)', 'x']) }

    it 'keeps each row under its renamed label' do
      expect(subject.row['none (1)'].to_a).to eq([2])
    end

    context 'when a row already has the label' do
      let(:index) { [nil, 'none', 'x'] }

      its('index.to_a') { is_expected.to eq(['none (1)', 'none', 'x']) }

      it 'keeps that row under the label' do
        expect(subject.row['none'].to_a).to eq([2])
      end
    end

    ['', nil].each do |blank|
      context "when the label is #{blank.inspect}" do
        subject { df.rename_blank_rows!(blank) }

        it { expect { subject }.to raise_error(ArgumentError, 'label must not be blank') }
      end
    end

    context 'when the index is named' do
      let(:index) { DaruLite::Index.new([nil, 'x', 'y'], name: 'rows') }

      its('index.name') { is_expected.to eq('rows') }
    end

    context 'when a numbered label is already taken' do
      let(:index) { [nil, '', 'none (1)'] }

      its('index.to_a') { is_expected.to eq(['none', 'none (2)', 'none (1)']) }
    end

    context 'when the other labels are not unique' do
      let(:index) { DaruLite::CategoricalIndex.new([nil, 'x', 'x']) }

      it { expect { subject }.to raise_error(ArgumentError, 'Labels must be unique, got duplicates: "x"') }

      it 'leaves the index untouched' do
        expect { subject rescue ArgumentError }.not_to(change { df.index.to_a })
      end
    end

    context 'with a whitespace-only label' do
      let(:index) { ['  ', 'x', 'y'] }

      its('index.to_a') { is_expected.to eq(%w[none x y]) }
    end

    context 'without blank labels' do
      let(:index) { %w[none x y] }

      its(:index) { is_expected.to equal(df.index) }
    end
  end
end
