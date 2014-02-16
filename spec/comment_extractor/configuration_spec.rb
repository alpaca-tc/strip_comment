require 'spec_helper'
require 'comment_extractor/configuration'

module CommentExtractor
  describe Configuration do
    describe '.new' do
      subject { CommentExtractor::Configuration.new(options) }
      let(:options) { { root_path: File.dirname(__FILE__) } }

      it 'sets attributes to default value' do
        expect(subject.extractors).to eql ExtractorManager.default_extractors
      end
    end

    describe '.add_setting' do
      before do
        # Initializes class variables
        @default_values = Configuration.class_variable_get(:@@default_values)
        @required_attributes = Configuration.class_variable_set(:@@required_attributes, {})
        Configuration.class_variable_set(:@@default_values, {})
        Configuration.class_variable_set(:@@required_attributes, {})

        Configuration.send(:add_setting, name, option_of_setting)
      end

      after do
        # Restores class variables
        Configuration.class_variable_set(:@@default_values, @default_values)
        Configuration.class_variable_set(:@@required_attributes, @required_attributes)
      end

      subject { Configuration.new(option_of_initialization) }
      let(:name) { :setting_name }
      let(:option_of_setting) { {} }
      let(:option_of_initialization) { {} }

      context 'given setting name' do
        it 'defines accessor method' do
          should be_respond_to name
          should be_respond_to "#{name}="
        end
      end

      context 'given default option' do
        let(:default_value) { 'default value' }
        let(:option_of_setting) { { default: default_value } }

        it 'initializations value by defualt value' do
          expect(subject.send(name)).to eql default_value
        end
      end

      context 'given predicate option' do
        let(:option_of_setting) { { predicate: true } }

        it 'defines predicate method(:name?)' do
          expect(subject).to be_respond_to("#{name}?")
        end
      end

      context 'given required option' do
        let(:option_of_setting) { { required: true } }

        context 'when initializations configuration without required attribute' do
          let(:message) { "Unable to initialize #{name} without attribute" }
          it { expect { subject }.to raise_error(message) }
        end

        context 'when initializations configuration with required attribute' do
          let(:option_of_initialization) { { name => true } }
          it { expect { subject }.to_not raise_error }
        end
      end
    end
  end
end
