shared_examples_for 'a calculatable Vector' do |dtype|
  describe '#count_values' do
    let(:vector) { DaruLite::Vector.new([1, 2, 3, 1, 2, nil, nil]) }

    it { expect(vector.count_values 1, 2).to eq 4 }
    it { expect(vector.count_values nil).to eq 2 }
    it { expect(vector.count_values 3, Float::NAN).to eq 1 }
    it { expect(vector.count_values 4).to eq 0 }
  end

  context "#summary" do
    subject { vector.summary }

    context 'all types' do
      let(:vector) { DaruLite::Vector.new([1 ,2, 3, 4, 5], name: 'vector') }

      it { is_expected.to include vector.name }

      it { is_expected.to include "n :#{vector.size}" }

      it { is_expected.to include "non-missing:#{vector.size - vector.count_values(*DaruLite::MISSING_VALUES)}" }
    end


    context "numeric type" do
      let(:vector) { DaruLite::Vector.new([1,2,5], name: 'numeric') }

      it { is_expected. to eq %Q{
          |= numeric
          |  n :3
          |  non-missing:3
          |  median: 2
          |  mean: 2.6667
          |  std.dev.: 2.0817
          |  std.err.: 1.2019
          |  skew: 0.2874
          |  kurtosis: -2.3333
        }.unindent }
    end

    context "numeric type with missing values" do
      let(:vector) { DaruLite::Vector.new([1,2,5,nil,Float::NAN], name: 'numeric') }

      it { is_expected.not_to include 'skew' }
      it { is_expected.not_to include 'kurtosis' }
    end

    if dtype == :array
      context "object type" do
        let(:vector) { DaruLite::Vector.new([1, 1, 2, 2, "string", nil, Float::NAN], name: 'object') }

        if RUBY_VERSION >= '2.2'
          it { is_expected.to eq %Q{
              |= object
              |  n :7
              |  non-missing:5
              |  factors: 1,2,string
              |  mode: 1,2
              |  Distribution
              |          string       1  50.00%
              |             NaN       1  50.00%
              |               1       2 100.00%
              |               2       2 100.00%
            }.unindent }
        else
          it { is_expected.to eq %Q{
            |= object
            |  n :7
            |  non-missing:5
            |  factors: 1,2,string
            |  mode: 1,2
            |  Distribution
            |             NaN       1  50.00%
            |          string       1  50.00%
            |               2       2 100.00%
            |               1       2 100.00%
          }.unindent }
        end
      end
    end
  end
end
