# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
describe 'Itly' do
  include RspecOptionsDefaultValues

  describe '#initialize' do
    let!(:itly) { Itly.new }

    it do
      expect(itly.instance_variable_get('@plugins_instances')).to eq([])
      expect(itly.instance_variable_get('@is_initialized')).to be(false)
    end
  end

  describe '#load' do
    let!(:itly) { Itly.new }
    let(:fake_logger) { double 'logger', info: nil }

    describe 'cannot be called twice' do
      before do
        itly.load
      end

      it do
        expect { itly.load }.to raise_error(Itly::InitializationError, 'Itly is already initialized.')
      end
    end

    describe '@options' do
      context 'without a block' do
        before do
          itly.load
        end

        it do
          expect_options_default_values itly.options
        end
      end

      context 'with a block' do
        before do
          itly.load do |o|
            o.context = { some: 'data' }
            o.disabled = :test_disabled
            o.environment = Itly::EnvironmentOptions::PRODUCTION
            o.validation = Itly::ValidationOptions::DISABLED
            o.destinations = { plugin_config: 'data' }
            o.logger = fake_logger
          end
        end

        it do
          expect(itly.options.disabled).to eq(:test_disabled)
          expect(itly.options.environment).to eq(Itly::EnvironmentOptions::PRODUCTION)
          expect(itly.options.validation).to eq(Itly::ValidationOptions::DISABLED)

          expect(itly.options.logger).to eq(fake_logger)

          destinations = itly.options.destinations
          expect(destinations).to be_a_kind_of(Itly::OptionsWrapper)
          expect(destinations.plugin_config).to eq('data')

          context = itly.options.context
          expect(context).to be_a_kind_of(Itly::Event)
          expect(context.name).to eq('context')
          expect(context.properties).to eq(some: 'data')
        end
      end
    end

    describe 'logging' do
      context 'enabled' do
        before do
          expect(fake_logger).to receive(:info).once.with('load()')
          expect(fake_logger).not_to receive(:info)
        end

        it do
          itly.load { |o| o.logger = fake_logger }
        end
      end

      context 'disabled' do
        before do
          expect(fake_logger).to receive(:info).once.with('Itly is disabled!')
          expect(fake_logger).to receive(:info).once.with('load()')
          expect(fake_logger).not_to receive(:info)
        end

        it do
          itly.load do |o|
            o.disabled = true
            o.logger = fake_logger
          end
        end
      end
    end

    describe 'plugins' do
      before do
        expect_any_instance_of(Itly).to receive(:instantiate_plugins)
        expect_any_instance_of(Itly).to receive(:send_to_plugins).and_wrap_original do |_, *args|
          expect(args.count).to eq(2)
          expect(args[0]).to eq(:init)
          expect(args[1].keys).to eq([:options])
          expect(args[1][:options].class).to eq(Itly::Options)
        end
      end

      it do
        itly.load
        expect(itly.plugins_instances).to eq([])
      end
    end
  end

  describe 'alias', :unload_itly, fake_plugins: 2, fake_plugins_methods: %i[init] do
    context 'default' do
      create_itly_object

      let!(:plugin_a) { itly.plugins_instances[0] }
      let!(:plugin_b) { itly.plugins_instances[1] }

      before do
        expect(itly.options.logger).to receive(:info)
          .with('alias(user_id: 123, previous_id: 456)')

        expect(plugin_a).to receive(:alias).with(user_id: '123', previous_id: '456')
        expect(plugin_b).to receive(:alias).with(user_id: '123', previous_id: '456')
        expect(plugin_a).to receive(:post_alias).with(user_id: '123', previous_id: '456')
        expect(plugin_b).to receive(:post_alias).with(user_id: '123', previous_id: '456')
      end

      it do
        itly.alias user_id: '123', previous_id: '456'
      end
    end

    context 'disabled' do
      create_itly_object disabled: true

      let!(:plugin_a) { itly.plugins_instances[0] }
      let!(:plugin_b) { itly.plugins_instances[1] }

      before do
        expect(itly.options.logger).not_to receive(:info)

        expect(plugin_a).not_to receive(:alias)
        expect(plugin_b).not_to receive(:alias)
        expect(plugin_a).not_to receive(:post_alias)
        expect(plugin_b).not_to receive(:post_alias)
      end

      it do
        itly.alias user_id: '123', previous_id: '456'
      end
    end
  end

  describe 'flush', :unload_itly, fake_plugins: 2, fake_plugins_methods: %i[init] do
    context 'default' do
      create_itly_object

      let!(:plugin_a) { itly.plugins_instances[0] }
      let!(:plugin_b) { itly.plugins_instances[1] }

      before do
        expect(itly.options.logger).to receive(:info).with('flush()')

        expect(plugin_a).to receive(:flush)
        expect(plugin_b).to receive(:flush)
      end

      it do
        itly.flush
      end
    end

    context 'disabled' do
      create_itly_object disabled: true

      let!(:plugin_a) { itly.plugins_instances[0] }
      let!(:plugin_b) { itly.plugins_instances[1] }

      before do
        expect(itly.options.logger).not_to receive(:info)

        expect(plugin_a).not_to receive(:flush)
        expect(plugin_b).not_to receive(:flush)
      end

      it do
        itly.flush
      end
    end
  end

  describe 'reset', :unload_itly, fake_plugins: 2, fake_plugins_methods: %i[init] do
    context 'default' do
      create_itly_object

      let!(:plugin_a) { itly.plugins_instances[0] }
      let!(:plugin_b) { itly.plugins_instances[1] }

      before do
        expect(itly.options.logger).to receive(:info).with('reset()')

        expect(plugin_a).to receive(:reset)
        expect(plugin_b).to receive(:reset)
      end

      it do
        itly.reset
      end
    end

    context 'disabled' do
      create_itly_object disabled: true

      let!(:plugin_a) { itly.plugins_instances[0] }
      let!(:plugin_b) { itly.plugins_instances[1] }

      before do
        expect(itly.options.logger).not_to receive(:info)

        expect(plugin_a).not_to receive(:reset)
        expect(plugin_b).not_to receive(:reset)
      end

      it do
        itly.reset
      end
    end
  end

  describe 'validate', :unload_itly, fake_plugins: 2, fake_plugins_methods: %i[init] do
    context 'default' do
      create_itly_object

      let!(:plugin_a) { itly.plugins_instances[0] }
      let!(:plugin_b) { itly.plugins_instances[1] }

      before do
        expect(itly.options.logger).to receive(:info).with('validate(event: an_event)')

        expect(plugin_a).to receive(:validate).with(event: 'an_event').and_return(nil)
        expect(plugin_b).to receive(:validate).with(event: 'an_event').and_return(:valitation_result)
      end

      it do
        expect(itly.validate(event: 'an_event')).to eq([:valitation_result])
      end
    end

    context 'disabled' do
      create_itly_object validation: Itly::ValidationOptions::DISABLED

      let!(:plugin_a) { itly.plugins_instances[0] }
      let!(:plugin_b) { itly.plugins_instances[1] }

      before do
        expect(itly.options.logger).not_to receive(:info)

        expect(plugin_a).not_to receive(:validate)
        expect(plugin_b).not_to receive(:validate)
      end

      it do
        expect(itly.validate(event: 'an_event')).to be(nil)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
