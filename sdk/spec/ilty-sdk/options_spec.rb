# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
describe Itly::Options do
  include RspecOptionsDefaultValues

  describe 'default values' do
    let!(:options) { Itly::Options.new }

    it do
      expect_options_default_values options
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

  describe '#initialize' do
    context 'no block' do
      let!(:itly) { Itly.new }

      it do
        expect_options_default_values itly.options
      end
    end

    context 'with a block' do
      let(:fake_logger) { double 'logger', info: nil }

      let!(:itly) do
        Itly.new do |o|
          o.context = :test_context
          o.disabled = :test_disabled
          o.environment = :test_environment
          o.destinations = :test_destinations
          o.logger = fake_logger
        end
      end

      it do
        expect(itly.options.context).to eq(:test_context)
        expect(itly.options.disabled).to eq(:test_disabled)
        expect(itly.options.environment).to eq(:test_environment)
        expect(itly.options.destinations).to eq(:test_destinations)
        expect(itly.options.logger).to eq(fake_logger)
      end
    end

    describe 'logging' do
      let(:fake_logger) { double 'logger', info: nil }

      context 'enabled' do
        before do
          expect(fake_logger).to receive(:info).once.with('load()')
          expect(fake_logger).not_to receive(:info)
        end

        it do
          Itly.new { |o| o.logger = fake_logger }
        end
      end

      context 'disabled' do
        before do
          expect(fake_logger).to receive(:info).once.with('Itly is disabled!')
          expect(fake_logger).to receive(:info).once.with('load()')
          expect(fake_logger).not_to receive(:info)
        end

        it do
          Itly.new do |o|
            o.disabled = true
            o.logger = fake_logger
          end
        end
      end
    end
  end

  describe '#disabled?' do
    context 'default' do
      let!(:itly) { Itly.new }

      it do
        expect(itly.send(:disabled?)).to be(false)
      end
    end

    context 'set to false' do
      let!(:itly) do
        Itly.new { |o| o.disabled = false }
      end

      it do
        expect(itly.send(:disabled?)).to be(false)
      end
    end

    context 'set to true' do
      let!(:itly) do
        Itly.new { |o| o.disabled = true }
      end

      it do
        expect(itly.send(:disabled?)).to be(true)
      end
    end
  end

  describe '#logger' do
    let(:fake_logger) { double 'logger', info: nil }

    context 'default' do
      let!(:itly) { Itly.new }

      it do
        expect(itly.send(:logger)).to be_a_kind_of(::Logger)
      end
    end

    context 'set to a value' do
      let!(:itly) do
        Itly.new { |o| o.logger = fake_logger }
      end

      it do
        expect(itly.send(:logger)).to eq(fake_logger)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
