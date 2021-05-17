# frozen_string_literal: true

describe Itly::Options do
  include RspecOptionsDefaultValues

  let!(:options) { Itly::Options.new }

  it 'should have default values'\
' (environment: DEVELOPMENT, validation: ERROR_ON_INVALID, plugins: [], logger: nil, disabled: false)' do
    expect_options_default_values options
  end

  it '#for_plugin' do
    expect(options.for_plugin).to be_a_kind_of(Itly::PluginOptions)
    expect(options.for_plugin.environment).to eq(Itly::Options::Environment::DEVELOPMENT)
    expect(options.for_plugin.logger).to be(nil)
  end

  describe 'validation' do
    context 'environment = DEVELOPMENT' do
      before do
        options.environment = Itly::Options::Environment::DEVELOPMENT
      end

      it 'default value should be ERROR_ON_INVALID' do
        expect(options.instance_variable_get('@validation')).to eq(Itly::Options::Validation::DEFAULT)
        expect(options.validation).to eq(Itly::Options::Validation::ERROR_ON_INVALID)
      end

      it 'setting validation should overwrite default value' do
        options.validation = Itly::Options::Validation::DISABLED

        expect(options.instance_variable_get('@validation')).to eq(Itly::Options::Validation::DISABLED)
        expect(options.validation).to eq(Itly::Options::Validation::DISABLED)
      end
    end

    context 'environment = PRODUCTION' do
      before do
        options.environment = Itly::Options::Environment::PRODUCTION
      end

      it 'default value should be TRACK_INVALID' do
        expect(options.instance_variable_get('@validation')).to eq(Itly::Options::Validation::DEFAULT)
        expect(options.validation).to eq(Itly::Options::Validation::TRACK_INVALID)
      end

      it 'setting validation should overwrite default value' do
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
    it 'should be readable' do
      expect(Itly.new.respond_to?(:options)).to be(true)
    end

    it 'should not be writable' do
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

    context 'when options.disabled = false' do
      let!(:itly) { Itly.new }

      before do
        itly.load { |o| o.disabled = false }
      end

      it do
        expect(itly.send(:enabled?)).to be(true)
      end
    end

    context 'when options.disabled = true' do
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

    context 'when options.disabled = true' do
      let!(:itly) { Itly.new }

      before do
        itly.load { |o| o.validation = Itly::Options::Validation::DISABLED }
      end

      it do
        expect(itly.send(:validation_enabled?)).to be(false)
      end
    end

    context 'when options.validation = TRACK_INVALID' do
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
        expect(itly.send(:logger)).to be(nil)
      end
    end

    context 'when a Logger is set' do
      let(:itly) { Itly.new }

      before do
        itly.load { |o| o.logger = fake_logger }
      end

      it 'is expected to be the set Logger' do
        expect(itly.send(:logger)).to eq(fake_logger)
      end
    end
  end
end
