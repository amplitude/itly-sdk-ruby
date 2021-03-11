# frozen_string_literal: true

describe 'Itly' do
  include RspecOptionsDefaultValues

  describe '#initialize' do
    let!(:itly) { Itly.new }

    it do
      expect(itly.instance_variable_get('@is_initialized')).to be(false)
    end
  end

  describe '#load' do
    let!(:itly) { Itly.new }
    let!(:fake_logger) { double 'logger', info: nil, warn: nil }

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

      context 'with a block', fake_plugins: 1 do
        before do
          itly.load do |o|
            o.context = { some: 'data' }
            o.disabled = true
            o.environment = Itly::Options::Environment::PRODUCTION
            o.validation = Itly::Options::Validation::DISABLED
            o.plugins = [FakePlugin0.new]
            o.logger = fake_logger
          end
        end

        it do
          expect(itly.options.disabled).to eq(true)
          expect(itly.options.environment).to eq(Itly::Options::Environment::PRODUCTION)
          expect(itly.options.validation).to eq(Itly::Options::Validation::DISABLED)

          expect(itly.options.logger).to eq(fake_logger)

          plugins = itly.options.plugins
          expect(plugins.count).to eq(1)
          expect(plugins[0]).to be_a_kind_of(FakePlugin0)

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
          expect(fake_logger).to receive(:info).once.with('load()')
          expect(fake_logger).to receive(:info).once.with('Itly is disabled!')
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

    describe 'environment' do
      context 'default value' do
        before do
          expect(fake_logger).to receive(:warn).once.with('Environment not specified. Automatically set to development')
          expect(fake_logger).to receive(:warn).once.with('No plugin enabled!')
          expect(fake_logger).not_to receive(:warn)
        end

        it do
          itly.load { |o| o.logger = fake_logger }

          expect(itly.options.environment).to eq(Itly::Options::Environment::DEVELOPMENT)
          expect(itly.options.instance_variable_get('@default_environment')).to be(true)
        end
      end

      [Itly::Options::Environment::DEVELOPMENT, Itly::Options::Environment::PRODUCTION].each do |value|
        context "set to #{value}" do
          before do
            expect(fake_logger).to receive(:warn).once.with('No plugin enabled!')
            expect(fake_logger).not_to receive(:warn)
          end

          it do
            itly.load do |options|
              options.logger = fake_logger
              options.environment = value
            end

            expect(itly.options.environment).to eq(value)
            expect(itly.options.instance_variable_get('@default_environment')).to be(false)
          end
        end
      end
    end

    describe 'plugins', fake_plugins: 2 do
      let!(:plugin_a) { FakePlugin0.new }
      let!(:plugin_b) { FakePlugin1.new }
      let!(:plugin_c) { FakePlugin1.new }

      before do
        [plugin_a, plugin_b, plugin_c].each do |plugin|
          expect(plugin).to receive(:load).and_wrap_original do |_, *args|
            expect(args.count).to eq(1)
            expect(args[0].keys).to eq([:options])
            expect(args[0][:options].class).to eq(Itly::Options)
          end
        end
      end

      it do
        itly.load do |options|
          options.plugins = [plugin_a, plugin_b, plugin_c]
        end
      end
    end
  end

  describe '#identify', fake_plugins: 2 do
    context 'Itly was not ititialized' do
      let!(:itly) { Itly.new }
      let!(:event) { Itly::Event.new name: 'Test' }

      before do
        expect(itly).not_to receive(:validate_and_send_to_plugins)
      end

      it do
        expect do
          itly.identify user_id: '123', properties: { data: '1', info: 'yes' }
        end.to raise_error(Itly::InitializationError, 'Itly is not initialized. Call #load { |options| ... }')
      end
    end

    context 'no validation error' do
      include_examples 'validate and run on plugins',
        method: :identify,
        method_params: { user_id: '123',
                         properties: { data: '1', info: 'yes' } },
        expected_event_properties: { data: '1', info: 'yes' },
        expected_log_info: 'identify(user_id: 123, properties: {:data=>"1", :info=>"yes"})'
    end

    context 'validation error' do
      context 'options.validation = DISABLED' do
        include_examples 'validate and run on plugins',
          method: :identify,
          method_params: { user_id: '123', properties: { data: '1', info: 'yes' } },
          validation_value: Itly::Options::Validation::DISABLED,
          expected_event_properties: { data: '1', info: 'yes' },
          expected_log_info: 'identify(user_id: 123, properties: {:data=>"1", :info=>"yes"})',
          generate_validation_error: true, expect_validation: false
      end

      context 'options.validation = TRACK_INVALID' do
        include_examples 'validate and run on plugins',
          method: :identify,
          method_params: { user_id: '123',
                           properties: { data: '1', info: 'yes' } },
          validation_value: Itly::Options::Validation::TRACK_INVALID,
          expected_event_properties: { data: '1', info: 'yes' },
          expected_log_info: 'identify(user_id: 123, properties: {:data=>"1", :info=>"yes"})',
          generate_validation_error: true
      end

      context 'options.validation = ERROR_ON_INVALID' do
        include_examples 'validate and run on plugins',
          method: :identify,
          method_params: { user_id: '123', properties: { data: '1', info: 'yes' } },
          validation_value: Itly::Options::Validation::ERROR_ON_INVALID,
          expected_event_properties: { data: '1', info: 'yes' },
          expected_log_info: 'identify(user_id: 123, properties: {:data=>"1", :info=>"yes"})',
          generate_validation_error: true, expect_to_call_action: false, expect_exception: true
      end
    end

    context 'disabled' do
      let!(:plugin_a) { FakePlugin0.new }
      let!(:plugin_b) { FakePlugin1.new }
      let!(:itly) { Itly.new }

      before do
        itly.load do |options|
          options.disabled = true
          options.plugins = [plugin_a, plugin_b]
        end
      end

      before do
        expect(itly.options.logger).not_to receive(:info)
        expect(itly.options.logger).not_to receive(:error)
        expect(itly).not_to receive(:validate_and_send_to_plugins)
      end

      it do
        itly.identify user_id: '123', properties: { data: '1', info: 'yes' }
      end
    end
  end

  describe '#group', fake_plugins: 2 do
    context 'Itly was not ititialized' do
      let(:itly) { Itly.new }
      let!(:event) { Itly::Event.new name: 'Test' }

      before do
        expect(itly).not_to receive(:validate_and_send_to_plugins)
      end

      it do
        expect do
          itly.group user_id: '123', group_id: '456', properties: { data: '1', info: 'yes' }
        end.to raise_error(Itly::InitializationError, 'Itly is not initialized. Call #load { |options| ... }')
      end
    end

    context 'no validation error' do
      include_examples 'validate and run on plugins',
        method: :group,
        method_params: { user_id: '123', group_id: '456',
                         properties: { data: '1', info: 'yes' } },
        expected_event_properties: { data: '1', info: 'yes' },
        expected_log_info: 'group(user_id: 123, group_id: 456, properties: {:data=>"1", :info=>"yes"})'
    end

    context 'validation error' do
      context 'options.validation = DISABLED' do
        include_examples 'validate and run on plugins',
          method: :group,
          method_params: { user_id: '123', group_id: '456', properties: { data: '1', info: 'yes' } },
          validation_value: Itly::Options::Validation::DISABLED,
          expected_event_properties: { data: '1', info: 'yes' },
          expected_log_info: 'group(user_id: 123, group_id: 456, properties: {:data=>"1", :info=>"yes"})',
          generate_validation_error: true, expect_validation: false
      end

      context 'options.validation = TRACK_INVALID' do
        include_examples 'validate and run on plugins',
          method: :group,
          method_params: { user_id: '123', group_id: '456',
                           properties: { data: '1', info: 'yes' } },
          validation_value: Itly::Options::Validation::TRACK_INVALID,
          expected_event_properties: { data: '1', info: 'yes' },
          expected_log_info: 'group(user_id: 123, group_id: 456, properties: {:data=>"1", :info=>"yes"})',
          generate_validation_error: true
      end

      context 'options.validation = ERROR_ON_INVALID' do
        include_examples 'validate and run on plugins',
          method: :group,
          method_params: { user_id: '123', group_id: '456', properties: { data: '1', info: 'yes' } },
          validation_value: Itly::Options::Validation::ERROR_ON_INVALID,
          expected_event_properties: { data: '1', info: 'yes' },
          expected_log_info: 'group(user_id: 123, group_id: 456, properties: {:data=>"1", :info=>"yes"})',
          generate_validation_error: true, expect_to_call_action: false, expect_exception: true
      end
    end

    context 'disabled' do
      let!(:plugin_a) { FakePlugin0.new }
      let!(:plugin_b) { FakePlugin1.new }
      let!(:itly) { Itly.new }

      before do
        itly.load do |options|
          options.disabled = true
          options.plugins = [plugin_a, plugin_b]
        end
      end

      before do
        expect(itly.options.logger).not_to receive(:info)
        expect(itly.options.logger).not_to receive(:error)
        expect(itly).not_to receive(:validate_and_send_to_plugins)
      end

      it do
        itly.group user_id: '123', group_id: '456', properties: { data: '1', info: 'yes' }
      end
    end
  end

  describe '#track', fake_plugins: 2 do
    context 'Itly was not ititialized' do
      let(:itly) { Itly.new }
      let!(:event) { Itly::Event.new name: 'Test' }

      before do
        expect(itly).not_to receive(:validate_and_send_to_plugins)
      end

      it do
        expect do
          itly.track user_id: '123', event: event
        end.to raise_error(Itly::InitializationError, 'Itly is not initialized. Call #load { |options| ... }')
      end
    end

    context 'without context' do
      context 'no validation error' do
        include_examples 'validate and run on plugins',
          method: :track,
          method_params: { user_id: '123', event:
                          Itly::Event.new(name: 'my_action', properties: { my: 'property' }) },
          event_keyword_name: :event,
          expected_validation_name: 'my_action',
          expected_event_properties: { my: 'property' },
          expected_log_info: 'track(user_id: 123, event: my_action, properties: {:my=>"property"})'
      end

      context 'validation error' do
        context 'options.validation = DISABLED' do
          include_examples 'validate and run on plugins',
            method: :track,
            method_params: { user_id: '123',
                             event: Itly::Event.new(name: 'my_action', properties: { my: 'property' }) },
            validation_value: Itly::Options::Validation::DISABLED,
            event_keyword_name: :event,
            expected_validation_name: 'my_action',
            expected_event_properties: { my: 'property' },
            expected_log_info: 'track(user_id: 123, event: my_action, properties: {:my=>"property"})',
            generate_validation_error: true,
            expect_validation: false
        end

        context 'options.validation = TRACK_INVALID' do
          include_examples 'validate and run on plugins',
            method: :track,
            method_params: { user_id: '123',
                             event: Itly::Event.new(name: 'my_action', properties: { my: 'property' }) },
            validation_value: Itly::Options::Validation::TRACK_INVALID,
            event_keyword_name: :event,
            expected_validation_name: 'my_action',
            expected_event_properties: { my: 'property' },
            expected_log_info: 'track(user_id: 123, event: my_action, properties: {:my=>"property"})',
            generate_validation_error: true
        end

        context 'options.validation = ERROR_ON_INVALID' do
          include_examples 'validate and run on plugins',
            method: :track,
            method_params: { user_id: '123',
                             event: Itly::Event.new(name: 'my_action', properties: { my: 'property' }) },
            validation_value: Itly::Options::Validation::ERROR_ON_INVALID,
            event_keyword_name: :event,
            expected_validation_name: 'my_action',
            expected_event_properties: { my: 'property' },
            expected_log_info: 'track(user_id: 123, event: my_action, properties: {:my=>"property"})',
            generate_validation_error: true,
            expect_to_call_action: false,
            expect_exception: true
        end
      end
    end

    context 'with context' do
      include_examples 'validate and run on plugins',
        method: :track,
        method_params: { user_id: '123', event: Itly::Event.new(name: 'my_action', properties: { my: 'property' }) },
        context_properties: { context_data: 'ABC' },
        event_keyword_name: :event,
        expected_validation_name: 'my_action',
        expected_event_properties: { my: 'property' },
        expected_log_info: 'track(user_id: 123, event: my_action, properties: {:my=>"property"})'
    end

    context 'disabled' do
      let!(:plugin_a) { FakePlugin0.new }
      let!(:plugin_b) { FakePlugin1.new }
      let!(:itly) { Itly.new }

      before do
        itly.load do |options|
          options.disabled = true
          options.plugins = [plugin_a, plugin_b]
        end
      end

      before do
        expect(itly.options.logger).not_to receive(:info)
        expect(itly.options.logger).not_to receive(:error)
        expect(itly).not_to receive(:validate_and_send_to_plugins)
      end

      it do
        itly.track user_id: '123', event: Itly::Event.new(name: 'my_action', properties: { my: 'property' })
      end
    end
  end

  describe '#alias' do
    include_examples 'runs on plugins',
      method: :alias,
      method_params: { user_id: '123', previous_id: '456' },
      expected_log_info: 'alias(user_id: 123, previous_id: 456)'
  end

  describe '#flush' do
    include_examples 'runs on plugins',
      method: :flush, no_post_method: true,
      expected_log_info: 'flush()'
  end

  describe '#reset' do
    include_examples 'runs on plugins',
      method: :reset, no_post_method: true,
      expected_log_info: 'reset()'
  end

  describe '#validate', fake_plugins: 2 do
    context 'Itly was not ititialized' do
      let(:itly) { Itly.new }
      let!(:event) { Itly::Event.new name: 'Test' }

      before do
        expect(itly).not_to receive(:run_on_plugins)
      end

      it do
        expect do
          itly.validate event: event
        end.to raise_error(Itly::InitializationError, 'Itly is not initialized. Call #load { |options| ... }')
      end
    end

    context 'default' do
      let!(:plugin_a) { FakePlugin0.new }
      let!(:plugin_b) { FakePlugin1.new }
      let!(:itly) { Itly.new }

      before do
        itly.load do |options|
          options.plugins = [plugin_a, plugin_b]
        end
      end

      let!(:event) { Itly::Event.new name: 'Test' }
      let!(:response) { Itly::ValidationResponse.new valid: true, plugin_id: 'plugin123' }

      before do
        expect(itly.options.logger).to receive(:info)
          .with('validate(event: #<Itly::Event: name: Test, properties: {}>)')

        expect(plugin_a).to receive(:validate).with(event: event).and_return(nil)
        expect(plugin_b).to receive(:validate).with(event: event).and_return(response)
      end

      it do
        expect(itly.validate(event: event)).to eq([response])
      end
    end

    context 'disabled' do
      let!(:plugin_a) { FakePlugin0.new }
      let!(:plugin_b) { FakePlugin1.new }
      let!(:itly) { Itly.new }

      before do
        itly.load do |options|
          options.validation = Itly::Options::Validation::DISABLED
          options.plugins = [plugin_a, plugin_b]
        end
      end
      let!(:event) { Itly::Event.new name: 'Test' }

      before do
        expect(itly.options.logger).not_to receive(:info)

        expect(plugin_a).not_to receive(:validate)
        expect(plugin_b).not_to receive(:validate)
      end

      it do
        expect(itly.validate(event: event)).to be(nil)
      end
    end
  end

  describe '#validate_and_send_to_plugins', fake_plugins: 2,
                                            fake_plugins_methods: %i[mock_action mock_post_action] do
    # Instanciate plugins, an event, and the Itly object
    let!(:plugin_a) { FakePlugin0.new }
    let!(:plugin_b) { FakePlugin1.new }
    let!(:event) { Itly::Event.new name: 'Test' }
    let!(:itly) { Itly.new }

    # Holder for examples to inject a validation option into Itly options
    let(:validation_option) { nil }

    # Load options
    before do
      itly.load do |options|
        options.context = { data: 'for_context' }
        options.plugins = [plugin_a, plugin_b]
        options.validation = validation_option if validation_option
      end
    end

    # Holders for ValidationResponse object that will be generated by the validation methods
    # Add an object in thos holders, and they will be generated
    # See the 'validate and send to plugins' shared example  for more info
    let(:generates_context_errors) { [] }
    let(:generates_event_errors) { [] }

    describe 'default' do
      context 'no context' do
        include_examples 'validate and send to plugins'

        it do
          itly.send :validate_and_send_to_plugins,
            event: event,
            action: ->(p, e) { p.mock_action e, :param },
            post_action: ->(p, e, v) { p.mock_post_action e, v, :other_param }
        end
      end

      context 'with context' do
        include_examples 'validate and send to plugins', with_context: true

        it do
          itly.send :validate_and_send_to_plugins,
            include_context: true, event: event,
            action: ->(p, e) { p.mock_action e, :param },
            post_action: ->(p, e, v) { p.mock_post_action e, v, :other_param }
        end
      end
    end

    context 'with context validation errors' do
      let(:response) { Itly::ValidationResponse.new valid: true, plugin_id: 'ABC', message: 'Error message' }
      let(:generates_context_errors) { [response] }

      context 'options.validation = DISABLED' do
        let(:validation_option) { Itly::Options::Validation::DISABLED }

        include_examples 'validate and send to plugins',
          with_context: true,
          receive_action_methods: false, is_valid: false

        it do
          itly.send :validate_and_send_to_plugins,
            include_context: true, event: event,
            action: ->(p, e) { p.mock_action e, :param },
            post_action: ->(p, e, v) { p.mock_post_action e, v, :other_param }
        end
      end

      context 'options.validation = TRACK_INVALID' do
        let(:validation_option) { Itly::Options::Validation::TRACK_INVALID }

        include_examples 'validate and send to plugins', with_context: true, is_valid: false

        it do
          itly.send :validate_and_send_to_plugins,
            include_context: true, event: event,
            action: ->(p, e) { p.mock_action e, :param },
            post_action: ->(p, e, v) { p.mock_post_action e, v, :other_param }
        end
      end

      context 'options.validation = ERROR_ON_INVALID' do
        let(:validation_option) { Itly::Options::Validation::ERROR_ON_INVALID }

        include_examples 'validate and send to plugins',
          with_context: true,
          receive_action_methods: false, is_valid: false

        it do
          itly.send :validate_and_send_to_plugins,
            include_context: true, event: event,
            action: ->(p, e) { p.mock_action e, :param },
            post_action: ->(p, e, v) { p.mock_post_action e, v, :other_param }
        end
      end
    end

    context 'with event validation errors' do
      let(:response) { Itly::ValidationResponse.new valid: true, plugin_id: 'ABC', message: 'Error message' }
      let(:generates_event_errors) { [response] }

      context 'options.validation = DISABLED' do
        let(:validation_option) { Itly::Options::Validation::DISABLED }

        include_examples 'validate and send to plugins',
          with_context: true,
          receive_action_methods: false, is_valid: false

        it do
          itly.send :validate_and_send_to_plugins,
            include_context: true, event: event,
            action: ->(p, e) { p.mock_action e, :param },
            post_action: ->(p, e, v) { p.mock_post_action e, v, :other_param }
        end
      end

      context 'options.validation = TRACK_INVALID' do
        let(:validation_option) { Itly::Options::Validation::TRACK_INVALID }

        include_examples 'validate and send to plugins', with_context: true, is_valid: false

        it do
          itly.send :validate_and_send_to_plugins,
            include_context: true, event: event,
            action: ->(p, e) { p.mock_action e, :param },
            post_action: ->(p, e, v) { p.mock_post_action e, v, :other_param }
        end
      end

      context 'options.validation = ERROR_ON_INVALID' do
        let(:validation_option) { Itly::Options::Validation::ERROR_ON_INVALID }

        include_examples 'validate and send to plugins',
          with_context: true,
          receive_action_methods: false, is_valid: false

        it do
          itly.send :validate_and_send_to_plugins,
            include_context: true, event: event,
            action: ->(p, e) { p.mock_action e, :param },
            post_action: ->(p, e, v) { p.mock_post_action e, v, :other_param }
        end
      end
    end

    context 'with validations errors' do
      let(:response1) { Itly::ValidationResponse.new valid: true, plugin_id: 'ABC', message: 'Error message' }
      let(:response2) { Itly::ValidationResponse.new valid: true, plugin_id: 'ABC', message: 'Error message' }
      let(:generates_context_errors) { [response1] }
      let(:generates_event_errors) { [response2] }

      context 'options.validation = DISABLED' do
        let(:validation_option) { Itly::Options::Validation::DISABLED }

        include_examples 'validate and send to plugins',
          with_context: true,
          receive_action_methods: false, is_valid: false

        it do
          itly.send :validate_and_send_to_plugins,
            include_context: true, event: event,
            action: ->(p, e) { p.mock_action e, :param },
            post_action: ->(p, e, v) { p.mock_post_action e, v, :other_param }
        end
      end

      context 'options.validation = TRACK_INVALID' do
        let(:validation_option) { Itly::Options::Validation::TRACK_INVALID }

        include_examples 'validate and send to plugins', with_context: true, is_valid: false

        it do
          itly.send :validate_and_send_to_plugins,
            include_context: true, event: event,
            action: ->(p, e) { p.mock_action e, :param },
            post_action: ->(p, e, v) { p.mock_post_action e, v, :other_param }
        end
      end

      context 'options.validation = ERROR_ON_INVALID' do
        let(:validation_option) { Itly::Options::Validation::ERROR_ON_INVALID }

        include_examples 'validate and send to plugins',
          with_context: true,
          receive_action_methods: false, is_valid: false

        it do
          itly.send :validate_and_send_to_plugins,
            include_context: true, event: event,
            action: ->(p, e) { p.mock_action e, :param },
            post_action: ->(p, e, v) { p.mock_post_action e, v, :other_param }
        end
      end
    end
  end

  describe 'validate_context_and_event', fake_plugins: 2, fake_plugins_methods: %i[validate] do
    context 'without context' do
      let!(:plugin_a) { FakePlugin0.new }
      let!(:plugin_b) { FakePlugin1.new }
      let!(:event) { Itly::Event.new name: 'Test' }
      let!(:itly) { Itly.new }

      before do
        itly.load do |options|
          options.plugins = [plugin_a, plugin_b]
        end
      end

      context 'no return from validations' do
        before do
          expect_to_receive_message_with_event plugin_a, :validate, name: 'Test'
          expect(plugin_a).not_to receive(:validate)

          expect_to_receive_message_with_event plugin_b, :validate, name: 'Test'
          expect(plugin_b).not_to receive(:validate)
        end

        it do
          expect(
            itly.send(:validate_context_and_event, true, event)
          ).to eq([[], [], true])
        end
      end

      context 'return from validations' do
        let(:response1) { Itly::ValidationResponse.new valid: true, plugin_id: '1', message: 'One' }
        let(:response2) { Itly::ValidationResponse.new valid: true, plugin_id: '2', message: 'Two' }

        context 'all valid' do
          before do
            expect(plugin_a).to receive(:validate).once.and_return(response1)
            expect(plugin_b).to receive(:validate).once.and_return(response2)
          end

          it do
            expect(
              itly.send(:validate_context_and_event, true, event)
            ).to eq([[], [response1, response2], true])
          end
        end

        context 'a validation returns false' do
          before do
            response1.valid = false

            expect(plugin_a).to receive(:validate).once.and_return(response1)
            expect(plugin_b).to receive(:validate).once.and_return(response2)
          end

          it do
            expect(
              itly.send(:validate_context_and_event, true, event)
            ).to eq([[], [response1, response2], false])
          end
        end
      end
    end

    context 'excluding context' do
      let!(:plugin_a) { FakePlugin0.new }
      let!(:plugin_b) { FakePlugin1.new }
      let!(:event) { Itly::Event.new name: 'Test' }
      let!(:itly) { Itly.new }

      before do
        itly.load do |options|
          options.context = { data: 'for_context' }
          options.plugins = [plugin_a, plugin_b]
        end
      end

      context 'no return from validations' do
        before do
          expect_to_receive_message_with_event plugin_a, :validate, name: 'Test'
          expect(plugin_a).not_to receive(:validate)

          expect_to_receive_message_with_event plugin_b, :validate, name: 'Test'
          expect(plugin_b).not_to receive(:validate)
        end

        it do
          expect(
            itly.send(:validate_context_and_event, false, event)
          ).to eq([[], [], true])
        end
      end

      context 'return from validations' do
        let(:response1) { Itly::ValidationResponse.new valid: true, plugin_id: '1', message: 'One' }
        let(:response2) { Itly::ValidationResponse.new valid: true, plugin_id: '2', message: 'Two' }

        context 'all valid' do
          before do
            expect(plugin_a).to receive(:validate).once.and_return(response1)
            expect(plugin_b).to receive(:validate).once.and_return(response2)
          end

          it do
            expect(
              itly.send(:validate_context_and_event, false, event)
            ).to eq([[], [response1, response2], true])
          end
        end

        context 'a validation returns false' do
          before do
            response1.valid = false

            expect(plugin_a).to receive(:validate).once.and_return(response1)
            expect(plugin_b).to receive(:validate).once.and_return(response2)
          end

          it do
            expect(
              itly.send(:validate_context_and_event, false, event)
            ).to eq([[], [response1, response2], false])
          end
        end
      end
    end

    context 'with context' do
      let!(:plugin_a) { FakePlugin0.new }
      let!(:plugin_b) { FakePlugin1.new }
      let!(:event) { Itly::Event.new name: 'Test' }
      let!(:itly) { Itly.new }

      before do
        itly.load do |options|
          options.context = { data: 'for_context' }
          options.plugins = [plugin_a, plugin_b]
        end
      end

      context 'no return from validations' do
        before do
          expect_to_receive_message_with_event plugin_a, :validate, name: 'context'
          expect_to_receive_message_with_event plugin_a, :validate, name: 'Test'
          expect(plugin_a).not_to receive(:validate)

          expect_to_receive_message_with_event plugin_b, :validate, name: 'context'
          expect_to_receive_message_with_event plugin_b, :validate, name: 'Test'
          expect(plugin_b).not_to receive(:validate)
        end

        it do
          expect(
            itly.send(:validate_context_and_event, true, event)
          ).to eq([[], [], true])
        end
      end

      context 'return from validations' do
        let(:response1) { Itly::ValidationResponse.new valid: true, plugin_id: '1', message: 'One' }
        let(:response2) { Itly::ValidationResponse.new valid: true, plugin_id: '2', message: 'Two' }
        let(:response3) { Itly::ValidationResponse.new valid: true, plugin_id: '3', message: 'Three' }

        context 'all valid' do
          before do
            expect(plugin_a).to receive(:validate).once.and_return(nil)
            expect(plugin_a).to receive(:validate).once.and_return(response1)
            expect(plugin_b).to receive(:validate).once.and_return(response2)
            expect(plugin_b).to receive(:validate).once.and_return(response3)
          end

          it do
            expect(
              itly.send(:validate_context_and_event, true, event)
            ).to eq([[response2], [response1, response3], true])
          end
        end

        context 'a context validation returns false' do
          before do
            response2.valid = false

            expect(plugin_a).to receive(:validate).once.and_return(nil)
            expect(plugin_a).to receive(:validate).once.and_return(response1)
            expect(plugin_b).to receive(:validate).once.and_return(response2)
            expect(plugin_b).to receive(:validate).once.and_return(response3)
          end

          it do
            expect(
              itly.send(:validate_context_and_event, true, event)
            ).to eq([[response2], [response1, response3], false])
          end
        end

        context 'a plugin validation returns false' do
          before do
            response1.valid = false

            expect(plugin_a).to receive(:validate).once.and_return(nil)
            expect(plugin_a).to receive(:validate).once.and_return(response1)
            expect(plugin_b).to receive(:validate).once.and_return(response2)
            expect(plugin_b).to receive(:validate).once.and_return(response3)
          end

          it do
            expect(
              itly.send(:validate_context_and_event, true, event)
            ).to eq([[response2], [response1, response3], false])
          end
        end
      end
    end
  end

  describe '#log_validation_errors' do
    let!(:itly) { Itly.new }
    let!(:event) { Itly::Event.new name: 'Test event' }

    before do
      itly.load
    end

    context 'validations is empty' do
      before do
        expect(itly.options.logger).not_to receive(:error)
      end

      it do
        itly.send :log_validation_errors, [], event
      end
    end

    context 'no validation error' do
      let(:response1) { Itly::ValidationResponse.new valid: true, plugin_id: '1', message: 'One' }
      let(:response2) { Itly::ValidationResponse.new valid: true, plugin_id: '2', message: 'Two' }

      before do
        expect(itly.options.logger).not_to receive(:error)
      end

      it do
        itly.send :log_validation_errors, [response1, response2], event
      end
    end

    context 'one error' do
      let(:response1) { Itly::ValidationResponse.new valid: true, plugin_id: 'pg_1', message: 'One' }
      let(:response2) { Itly::ValidationResponse.new valid: false, plugin_id: 'pg_2', message: 'Two' }

      before do
        expect(itly.options.logger).to receive(:error).once
          .with('Validation error for "Test event" in pg_2. Message: Two')
        expect(itly.options.logger).not_to receive(:error)
      end

      it do
        itly.send :log_validation_errors, [response1, response2], event
      end
    end

    context 'multiple errors' do
      let(:response1) { Itly::ValidationResponse.new valid: false, plugin_id: 'pg_1', message: 'One' }
      let(:response2) { Itly::ValidationResponse.new valid: false, plugin_id: 'pg_2', message: 'Two' }

      before do
        expect(itly.options.logger).to receive(:error).once
          .with('Validation error for "Test event" in pg_1. Message: One')
        expect(itly.options.logger).to receive(:error).once
          .with('Validation error for "Test event" in pg_2. Message: Two')
        expect(itly.options.logger).not_to receive(:error)
      end

      it do
        itly.send :log_validation_errors, [response1, response2], event
      end
    end
  end

  describe '#raise_validation_errors' do
    # Instanciate
    let!(:event) { Itly::Event.new name: 'Test event' }
    let!(:itly) { Itly.new }

    # Holder for examples to inject a validation option into Itly options
    let(:validation_option) { Itly::Options::Validation::ERROR_ON_INVALID }

    # Load options
    before do
      itly.load do |options|
        options.validation = validation_option
      end
    end

    it 'is valid' do
      expect { itly.send :raise_validation_errors, true, [], event }.not_to raise_error
    end

    context 'validation is DISABLED' do
      let(:validation_option) { Itly::Options::Validation::DISABLED }

      it do
        expect { itly.send :raise_validation_errors, false, [], event }.not_to raise_error
      end
    end

    context 'validation is TRACK_INVALID' do
      let(:validation_option) { Itly::Options::Validation::TRACK_INVALID }

      it do
        expect { itly.send :raise_validation_errors, false, [], event }.not_to raise_error
      end
    end

    it 'no validation message' do
      expect { itly.send :raise_validation_errors, false, [], event }
        .to raise_error(Itly::ValidationError, 'Unknown error validating Test event')
    end

    context 'no failing validation message' do
      let(:response1) { Itly::ValidationResponse.new valid: true, plugin_id: 'pg_1', message: 'One' }
      let(:response2) { Itly::ValidationResponse.new valid: true, plugin_id: 'pg_2', message: 'Two' }

      it do
        expect { itly.send :raise_validation_errors, false, [response1, response2], event }
          .to raise_error(Itly::ValidationError, 'Unknown error validating Test event')
      end
    end

    context 'with failing validation message' do
      let(:response1) { Itly::ValidationResponse.new valid: false, plugin_id: 'pg_1', message: 'One' }
      let(:response2) { Itly::ValidationResponse.new valid: false, plugin_id: 'pg_2', message: 'Two' }

      it do
        expect { itly.send :raise_validation_errors, false, [response1, response2], event }
          .to raise_error(Itly::ValidationError, 'One')
      end
    end
  end
end
