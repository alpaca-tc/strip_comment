require 'spec_helper'

class StripComment::Scanner
  describe Sqs do
    let(:klass) { Sqs }
    it { pending 'scanner' }

    describe '#disabled?' do
      subject { klass.disabled? }
      it { should be_truthy }
    end
  end
end
