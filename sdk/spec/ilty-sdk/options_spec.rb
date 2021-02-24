# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
describe Itly::Options do
  include RspecOptionsDefaultValues

  let!(:options) { Itly::Options.new }

  it 'default values' do
    expect_options_default_values options
  end

  it '#context=' do
    options.context = { a: 1, b: 'two' }

    expect(options.context).to be_a_kind_of(Itly::Event)
    expect(options.context.name).to eq('context')
    expect(options.context.properties).to eq(a: 1, b: 'two')
  end

  describe '#destinations=' do
    it 'set underlying values' do
      options.destinations = { a: 1, b: 'two' }

      expect(options.destinations).to be_a_kind_of(Itly::OptionsWrapper)
      expect(options.destinations.a).to eq(1)
      expect(options.destinations.b).to eq('two')
    end

    it 'clean befor allowating' do
      options.destinations = { a: 1 }
      options.destinations = { b: 2 }

      expect(options.destinations.b).to eq(2)
      expect { options.destinations.a }.to raise_error(NoMethodError)
    end
  end

  describe 'validation' do
    context 'development' do
      before do
        options.environment = Itly::EnvironmentOptions::DEVELOPMENT
      end

      it 'default value' do
        expect(options.instance_variable_get('@validation')).to eq(Itly::ValidationOptions::DEFAULT)
        expect(options.validation).to eq(Itly::ValidationOptions::ERROR_ON_INVALID)
      end

      it 'overwite value' do
        options.validation = Itly::ValidationOptions::DISABLED

        expect(options.instance_variable_get('@validation')).to eq(Itly::ValidationOptions::DISABLED)
        expect(options.validation).to eq(Itly::ValidationOptions::DISABLED)
      end
    end

    context 'production' do
      before do
        options.environment = Itly::EnvironmentOptions::PRODUCTION
      end

      it 'default value' do
        expect(options.instance_variable_get('@validation')).to eq(Itly::ValidationOptions::DEFAULT)
        expect(options.validation).to eq(Itly::ValidationOptions::TRACK_INVALID)
      end

      it 'overwite value' do
        options.validation = Itly::ValidationOptions::DISABLED

        expect(options.instance_variable_get('@validation')).to eq(Itly::ValidationOptions::DISABLED)
        expect(options.validation).to eq(Itly::ValidationOptions::DISABLED)
      end
    end
  end
end

describe Itly do
  include RspecOptionsDefaultValues

  describe 'instance attributes' do
    it 'can read' do
      expect(Itly.new.respond_to?(:options)).to be(true)
    end

    it 'cannot write' do
      expect(Itly.new.respond_to?(:options=)).to be(false)
    end
  end

  describe '#disabled?' do
    context 'default' do
      create_itly_object

      it do
        expect(itly.send(:disabled?)).to be(false)
      end
    end

    context 'set to false' do
      create_itly_object disabled: false

      it do
        expect(itly.send(:disabled?)).to be(false)
      end
    end

    context 'set to true' do
      create_itly_object disabled: true

      it do
        expect(itly.send(:disabled?)).to be(true)
      end
    end
  end

  describe '#logger' do
    let(:fake_logger) { double 'logger', info: nil }

    context 'default' do
      create_itly_object

      it do
        expect(itly.send(:logger)).to be_a_kind_of(::Logger)
      end
    end

    context 'set a value' do
      let(:itly) { Itly.new }

      before do
        itly.load { |o| o.logger = fake_logger }
      end

      it do
        expect(itly.send(:logger)).to eq(fake_logger)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
