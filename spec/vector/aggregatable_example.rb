shared_examples_for 'an aggregatable Vector' do
  context "#group_by" do
    let(:dv) { DaruLite::Vector.new [:a, :b, :a, :b, :c] }

    context 'vector not specified' do
      subject { dv.group_by }

      it { is_expected.to be_a DaruLite::Core::GroupBy }
      its(:'groups.size') { is_expected.to eq 3 }
      its(:groups) { is_expected.to eq({[:a]=>[0, 2], [:b]=>[1, 3], [:c]=>[4]}) }
    end

    context 'vector name specified' do
      before { dv.name = :hello }
      subject { dv.group_by :hello }

      it { is_expected.to be_a DaruLite::Core::GroupBy }
      its(:'groups.size') { is_expected.to eq 3 }
      its(:groups) { is_expected.to eq({[:a]=>[0, 2], [:b]=>[1, 3], [:c]=>[4]}) }
    end

    context 'vector name invalid' do
      before { dv.name = :hello }
      it { expect { dv.group_by :abc }.to raise_error }
    end
  end
end
