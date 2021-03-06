# frozen_string_literal: true

describe Itly::Options do
  include RspecOptionsDefaultValues

  let!(:options) { Itly::Options.new }

  it 'default values' do
    expect_options_default_values options
  end

  it '#context=' do
    options.context = { a: '1', b: 'two' }

    expect(options.context).to be_a_kind_of(Itly::Event)
    expect(options.context.name).to eq('context')
    expect(options.context.properties).to eq(a: '1', b: 'two')
  end

  it '#environment=' do
    expect(options.instance_variable_get('@default_environment')).to be(true)
    expect(options.environment).to eq(Itly::Options::Environment::DEVELOPMENT)

    options.environment = Itly::Options::Environment::DEVELOPMENT
    expect(options.instance_variable_get('@default_environment')).to be(false)
    expect(options.environment).to eq(Itly::Options::Environment::DEVELOPMENT)

    options.environment = Itly::Options::Environment::PRODUCTION
    expect(options.instance_variable_get('@default_environment')).to be(false)
    expect(options.environment).to eq(Itly::Options::Environment::PRODUCTION)
  end

  describe 'validation' do
    context 'development' do
      before do
        options.environment = Itly::Options::Environment::DEVELOPMENT
      end

      it 'default value' do
        expect(options.instance_variable_get('@validation')).to eq(Itly::Options::Validation::DEFAULT)
        expect(options.validation).to eq(Itly::Options::Validation::ERROR_ON_INVALID)
      end

      it 'overwite value' do
        options.validation = Itly::Options::Validation::DISABLED

        expect(options.instance_variable_get('@validation')).to eq(Itly::Options::Validation::DISABLED)
        expect(options.validation).to eq(Itly::Options::Validation::DISABLED)
      end
    end

    context 'production' do
      before do
        options.environment = Itly::Options::Environment::PRODUCTION
      end

      it 'default value' do
        expect(options.instance_variable_get('@validation')).to eq(Itly::Options::Validation::DEFAULT)
        expect(options.validation).to eq(Itly::Options::Validation::TRACK_INVALID)
      end

      it 'overwite value' do
        options.validation = Itly::Options::Validation::DISABLED

        expect(options.instance_variable_get('@validation')).to eq(Itly::Options::Validation::DISABLED)
        expect(options.validation).to eq(Itly::Options::Validation::DISABLED)
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

  describe '#enabled?' do
    context 'default' do
      let!(:itly) { Itly.new }

      before do
        itly.load
      end

      it do
        expect(itly.send(:enabled?)).to be(true)
      end
    end

    context 'set to false' do
      let!(:itly) { Itly.new }

      before do
        itly.load { |o| o.disabled = false }
      end

      it do
        expect(itly.send(:enabled?)).to be(true)
      end
    end

    context 'set to true' do
      let!(:itly) { Itly.new }

      before do
        itly.load { |o| o.disabled = true }
      end

      it do
        expect(itly.send(:enabled?)).to be(false)
      end
    end
  end

  describe '#validation_enabled?' do
    context 'default' do
      let!(:itly) { Itly.new }

      before do
        itly.load
      end

      it do
        expect(itly.send(:validation_enabled?)).to be(true)
      end
    end

    context 'set to disabled' do
      let!(:itly) { Itly.new }

      before do
        itly.load { |o| o.validation = Itly::Options::Validation::DISABLED }
      end

      it do
        expect(itly.send(:validation_enabled?)).to be(false)
      end
    end

    context 'set to another value' do
      let!(:itly) { Itly.new }

      before do
        itly.load { |o| o.validation = Itly::Options::Validation::TRACK_INVALID }
      end

      it do
        expect(itly.send(:validation_enabled?)).to be(true)
      end
    end
  end

  describe '#logger' do
    let(:fake_logger) { double 'logger', info: nil, warn: nil }

    context 'default' do
      let!(:itly) { Itly.new }

      before do
        itly.load
      end

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
