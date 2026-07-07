require 'spec_helper.rb'

describe DaruLite::CategoricalIndex do
  let(:index) { described_class.new(keys) }
  let(:keys) { [:a, :b, :a, :a, :c] }

  describe "#to_a" do
    subject { index.to_a }

    it { is_expected.to eq(keys) }

    it 'the returns array is not a variable of the index' do
      expect { subject << 'four' }.not_to change { index.to_a }
    end
  end

  context "#pos" do
    context "when the category is non-numeric" do
      context "single category" do
        subject { index.pos :a }

        it { is_expected.to eq [0, 2, 3] }
      end

      context "multiple categories" do
        subject { index.pos :a, :c }

        it { is_expected.to eq [0, 2, 3, 4] }
      end

      context "invalid category" do
        it { expect { index.pos :e }.to raise_error IndexError }
      end

      context "label range argument" do
        it { expect { index.pos :a..:c }.to raise_error ArgumentError }
      end

      context "positional (integer) range argument" do
        it { expect(index.pos(0..2)).to eq [0, 1, 2] }

        context "when the range extends past the end" do
          it { expect(index.pos(0..99)).to eq [0, 1, 2, 3, 4] }
        end
      end

      context "when a category is itself a Range" do
        let(:index) { described_class.new [(1..2), (3..4), (1..2)] }

        it { expect(index.pos(1..2)).to eq [0, 2] }
      end

      context "positional index" do
        it { expect(index.pos 0).to eq 0 }
      end

      context "invalid positional index" do
        it { expect { index.pos 5 }.to raise_error IndexError }
      end

      context "multiple positional indexes" do
        subject { index.pos 0, 1, 2 }

        it { is_expected.to be_a Array }
        its(:size) { is_expected.to eq 3 }
        it { is_expected.to eq [0, 1, 2] }
      end
    end

    context "when the category is numeric" do
      let(:idx) { described_class.new [0, 1, 0, 0, 2] }

      context "first preference to category" do
        subject { idx.pos 0 }

        it { is_expected.to be_a Array }
        its(:size) { is_expected.to eq 3 }
        it { is_expected.to eq [0, 2, 3] }
      end

      context "second preference to positional index" do
        subject { idx.pos 3 }

        it { is_expected.to eq 3 }
      end
    end
  end

  describe "#[]" do
    context "when the category occurs once" do
      subject { index[:b] }

      it { is_expected.to eq 1 }
    end

    context "when the category occurs multiple times" do
      subject { index[:a] }

      it { is_expected.to eq [0, 2, 3] }
    end

    context "when given a positional index" do
      subject { index[0] }

      it { is_expected.to eq 0 }
    end

    context "when given multiple categories" do
      subject { index[:a, :c] }

      it { is_expected.to eq [0, 2, 3, 4] }
    end

    context "when the category is absent" do
      subject { index[:z] }

      it { is_expected.to be_nil }
    end

    context "when given a label range" do
      it { expect { index[:a..:c] }.to raise_error ArgumentError }
    end

    context "when given a positional (integer) range" do
      subject { index[0..2] }

      it { is_expected.to eq [0, 1, 2] }
    end

    context "when a category is itself a Range" do
      let(:index) { described_class.new [(1..2), (3..4), (1..2)] }

      it { expect(index[1..2]).to eq [0, 2] }
    end
  end

  describe "#key" do
    context "when given a position" do
      subject { index.key(1) }

      it { is_expected.to eq :b }
    end

    context "when the position holds a duplicated category" do
      subject { index.key(3) }

      it { is_expected.to eq :a }
    end

    context "when the position is out of range" do
      subject { index.key(99) }

      it { is_expected.to be_nil }
    end

    context "when given a non-numeric value" do
      subject { index.key(:a) }

      it { is_expected.to be_nil }
    end
  end

  describe "#slice" do
    it { expect { index.slice(:a, :c) }.to raise_error ArgumentError }
  end

  describe "#subset_slice" do
    it { expect { index.subset_slice(:a, :c) }.to raise_error ArgumentError }
  end

  context "#subset" do
    let(:idx) { described_class.new [:a, 1, :a, 1, :c] }

    context "single index" do
      context "multiple instances" do
        subject { idx.subset :a }

        it { is_expected.to be_a described_class }
        its(:size) { is_expected.to eq 2 }
        its(:to_a) { is_expected.to eq [:a, :a] }
      end
    end

    context "multiple indexes" do
      subject { idx.subset :a, 1 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 4 }
      its(:to_a) { is_expected.to eq [:a, 1, :a, 1] }
    end

    context "multiple positional indexes" do
      subject { idx.subset 0, 2 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 2 }
      its(:to_a) { is_expected.to eq [:a, :a] }
    end
  end

  context "#at" do
    let(:idx) { described_class.new [:a, :a, :a, 1, :c] }

    context "single position" do
      it { expect(idx.at 1).to eq :a }
    end

    context "multiple positions" do
      subject { idx.at 0, 2, 3 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 3 }
      its(:to_a) { is_expected.to eq [:a, :a, 1] }
    end

    context "range" do
      subject { idx.at 2..3 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 2 }
      its(:to_a) { is_expected.to eq [:a, 1] }
    end

    context "range with negative integers" do
      subject { idx.at 2..-2 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 2 }
      its(:to_a) { is_expected.to eq [:a, 1] }
    end

    context "rangle with single element" do
      subject { idx.at 2..2 }

      it { is_expected.to be_a described_class }
      its(:size) { is_expected.to eq 1 }
      its(:to_a) { is_expected.to eq [:a] }
    end

    context "invalid position" do
      it { expect { idx.at 5 }.to raise_error IndexError }
    end

    context "invalid positions" do
      it { expect { idx.at 2, 5 }.to raise_error IndexError }
    end
  end

  context "#add" do
    let(:idx) { described_class.new [:a, 1, :a, 1] }

    context "single index" do
      subject { idx.add :c }

      its(:to_a) { is_expected.to eq [:a, 1, :a, 1, :c] }
      its(:categories) { is_expected.to eq [:a, 1, :c] }
    end

    context "multiple indexes" do
      subject { idx.add :c, :d }

      its(:to_a) { is_expected.to eq [:a, 1, :a, 1, :c, :d] }
      its(:categories) { is_expected.to eq [:a, 1, :c, :d] }
    end
  end

  context "#valid?" do
    let(:idx) { described_class.new [:a, 1, :a, 1] }

    context "single index" do
      it { expect(idx.valid? :a).to eq true }
      it { expect(idx.valid? 2).to eq true }
      it { expect(idx.valid? 4).to eq false }
    end

    context "multiple indexes" do
      it { expect(idx.valid? :a, 1).to eq true }
      it { expect(idx.valid? :a, 1, 5).to eq false }
    end
  end

  describe '#delete_at' do
    subject { index.delete_at(3) }

    let(:index) { described_class.new([:a, 1, :a, 1, 'c']) }

    it { is_expected.to eq(described_class.new([:a, 1, :a, 'c'])) }
  end
end
