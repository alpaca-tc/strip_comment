require 'spec_helper'

class StripComment::Scanner
  describe Markdown do
    let(:klass) { Markdown }
    it { pending 'scanner' }

    describe '#disabled?' do
      subject { klass.disabled? }
      it { should be_truthy }
    end
  end
end
