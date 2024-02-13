require 'spec_helper'

describe '#error' do
  context 'by default' do
    it { expect { DaruLite.error('test') }.to output("test\n").to_stderr_from_any_process }
  end

  context 'when set to nil' do
    before { DaruLite.error_stream = nil }
    it { expect { DaruLite.error('test') }.not_to output('test').to_stderr_from_any_process }
  end

  context 'when set to instance of custom class' do
    let(:custom_stream) { double(puts: nil) }
    before { DaruLite.error_stream = custom_stream }

    it 'calls puts' do
      expect { DaruLite.error('test') }.not_to output('test').to_stderr_from_any_process
      expect(custom_stream).to have_received(:puts).with('test')
    end
  end
end
