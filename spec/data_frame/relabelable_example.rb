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

    ['', '  ', false].each do |name|
      context "with a vector named #{name.inspect}" do
        let(:blank_name) { name }

        its('vectors.to_a') { is_expected.to eq(%i[none b]) }
      end
    end

    context 'without blank vector names' do
      let(:blank_name) { :a }

      its('vectors.to_a') { is_expected.to eq(%i[a b]) }
    end

    context 'when a vector already has the label' do
      let(:df) { DaruLite::DataFrame.new({ none: [1, 2], nil => [3, 4] }) }

      it 'overwrites it with the blank vector' do
        expect(subject[:none].to_a).to eq([3, 4])
      end
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
      let(:index) { ['none', nil, 'x'] }

      its('index.to_a') { is_expected.to eq(['none', 'none (1)', 'x']) }
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
