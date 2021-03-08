# frozen_string_literal: true

describe Itly::PluginIteratively do
  include RspecLoggerHelpers

  describe 'instance attributes' do
    let(:plugin) { Itly::PluginIteratively.new url: 'http://url', api_key: 'key123' }

    it 'can read' do
      expect(plugin.respond_to?(:logger)).to be(true)
      expect(plugin.respond_to?(:disabled)).to be(true)
      expect(plugin.respond_to?(:client)).to be(true)
      expect(plugin.respond_to?(:url)).to be(true)
      expect(plugin.respond_to?(:api_key)).to be(true)
    end

    it 'cannot write' do
      expect(plugin.respond_to?(:logger=)).to be(false)
      expect(plugin.respond_to?(:disabled=)).to be(false)
      expect(plugin.respond_to?(:client=)).to be(false)
      expect(plugin.respond_to?(:url=)).to be(false)
      expect(plugin.respond_to?(:api_key=)).to be(false)
    end
  end

  describe '#initialize' do
    let!(:plugin) { Itly::PluginIteratively.new url: 'http://url', api_key: 'key123' }

    it do
      expect(plugin.instance_variable_get('@url')).to eq('http://url')
      expect(plugin.instance_variable_get('@api_key')).to eq('key123')
    end
  end

  describe '#load' do
    let(:logs) { StringIO.new }
    let(:fake_logger) { double 'logger', info: nil, warn: nil }
    let(:plugin) { Itly::PluginIteratively.new url: 'http://url', api_key: 'key123' }
    let(:itly) { Itly.new }

    describe 'properties' do
      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = fake_logger
        end
      end

      it do
        expect(plugin.client).to be_a_kind_of(::Itly::PluginIteratively::Client)
        expect(plugin.client.url).to eq('http://url')
        expect(plugin.client.api_key).to eq('key123')
        expect(plugin.logger).to eq(fake_logger)
        expect(plugin.disabled).to be(false)
      end
    end

    describe 'disabled' do
      include_examples 'plugin load disabled value',
        environment: Itly::Options::Environment::DEVELOPMENT, expected: false
      include_examples 'plugin load disabled value',
        environment: Itly::Options::Environment::PRODUCTION, expected: true
      include_examples 'plugin load disabled value',
        environment: Itly::Options::Environment::DEVELOPMENT, disabled: false, expected: false
      include_examples 'plugin load disabled value',
        environment: Itly::Options::Environment::PRODUCTION, disabled: false, expected: true
      include_examples 'plugin load disabled value',
        environment: Itly::Options::Environment::DEVELOPMENT, disabled: true, expected: true
      include_examples 'plugin load disabled value',
        environment: Itly::Options::Environment::PRODUCTION, disabled: true, expected: true
    end

    describe 'logs' do
      context 'plugin enabled' do
        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
            options.environment = Itly::Options::Environment::DEVELOPMENT
          end
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'plugin_iteratively: load()']
          ]
        end
      end

      context 'plugin disabled' do
        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
            options.environment = Itly::Options::Environment::DEVELOPMENT
            options.disabled = true
          end
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'Itly is disabled!'],
            ['info', 'plugin_iteratively: load()'],
            ['info', 'plugin_iteratively: plugin is disabled!']
          ]
        end
      end
    end
  end

  describe '#post_identify' do
    let(:logs) { StringIO.new }
    let(:plugin) { Itly::PluginIteratively.new url: 'http://url', api_key: 'key123' }
    let(:itly) { Itly.new }

    context 'success' do
      let(:expected_event) { Itly::Event.new name: 'identify', properties: { some: 'data' } }

      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
        end

        expect(plugin).to receive(:client_track).with('identify', expected_event, [])

        itly.identify user_id: 'user_123', properties: { some: 'data' }
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['warn', 'Environment not specified. Automatically set to development'],
          ['info', 'plugin_iteratively: load()'],
          ['info', 'identify(user_id: user_123, properties: {:some=>"data"})'],
          ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:some=>"data"}>)'],
          ['info', 'plugin_iteratively: post_identify(user_id: user_123, properties: #<Itly::Event: '\
                    'name: identify, properties: {:some=>"data"}>, validation_results: [])']
        ]
      end
    end

    context 'with validation messages' do
      let(:expected_event) { Itly::Event.new name: 'identify', properties: { some: 'data' } }
      let(:response) { Itly::ValidationResponse.new valid: true, plugin_id: 'test-plg' }
      let(:validator) { Itly::Plugin.new }

      before do
        expect(validator).to receive(:validate).once.with(event: expected_event).and_return(response)
        expect(validator).not_to receive(:validate)

        itly.load do |options|
          options.plugins = [plugin, validator]
          options.logger = ::Logger.new logs
        end

        expect(plugin).to receive(:client_track).with('identify', expected_event, [response])

        itly.identify user_id: 'user_123', properties: { some: 'data' }
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['warn', 'Environment not specified. Automatically set to development'],
          ['info', 'plugin_iteratively: load()'],
          ['info', 'identify(user_id: user_123, properties: {:some=>"data"})'],
          ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:some=>"data"}>)'],
          ['info', 'plugin_iteratively: post_identify(user_id: user_123, properties: #<Itly::Event: '\
                   'name: identify, properties: {:some=>"data"}>, validation_results: [#<Itly::ValidationResponse: '\
                   'valid: true, plugin_id: test-plg, message: >])']
        ]
      end
    end

    context 'disabled' do
      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
          options.environment = Itly::Options::Environment::PRODUCTION
        end

        expect(plugin).not_to receive(:client_track)

        itly.identify user_id: 'user_123', properties: { some: 'data' }
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['info', 'plugin_iteratively: load()'],
          ['info', 'plugin_iteratively: plugin is disabled!'],
          ['info', 'identify(user_id: user_123, properties: {:some=>"data"})'],
          ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:some=>"data"}>)']
        ]
      end
    end

    context 'failure' do
      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
          options.environment = Itly::Options::Environment::DEVELOPMENT
        end

        expect(plugin.client).to receive(:track).and_raise('Testing')
      end

      it do
        expect do
          itly.identify user_id: 'user_123', properties: { some: 'data' }
        end.to raise_error(RuntimeError, 'Testing')
      end
    end
  end

  describe '#post_group' do
    let(:logs) { StringIO.new }
    let(:plugin) { Itly::PluginIteratively.new url: 'http://url', api_key: 'key123' }
    let(:itly) { Itly.new }

    context 'success' do
      let(:expected_event) { Itly::Event.new name: 'group', properties: { some: 'data' } }

      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
        end

        expect(plugin).to receive(:client_track).with('group', expected_event, [])

        itly.group user_id: 'user_123', group_id: 'group456', properties: { some: 'data' }
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['warn', 'Environment not specified. Automatically set to development'],
          ['info', 'plugin_iteratively: load()'],
          ['info', 'group(user_id: user_123, group_id: group456, properties: {:some=>"data"})'],
          ['info', 'validate(event: #<Itly::Event: name: group, properties: {:some=>"data"}>)'],
          ['info', 'plugin_iteratively: post_group(user_id: user_123, group_id: group456, properties: #<Itly::Event: '\
                    'name: group, properties: {:some=>"data"}>, validation_results: [])']
        ]
      end
    end

    context 'with validation messages' do
      let(:expected_event) { Itly::Event.new name: 'group', properties: { some: 'data' } }
      let(:response) { Itly::ValidationResponse.new valid: true, plugin_id: 'test-plg' }
      let(:validator) { Itly::Plugin.new }

      before do
        expect(validator).to receive(:validate).once.with(event: expected_event).and_return(response)
        expect(validator).not_to receive(:validate)

        itly.load do |options|
          options.plugins = [plugin, validator]
          options.logger = ::Logger.new logs
        end

        expect(plugin).to receive(:client_track).with('group', expected_event, [response])

        itly.group user_id: 'user_123', group_id: 'group456', properties: { some: 'data' }
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['warn', 'Environment not specified. Automatically set to development'],
          ['info', 'plugin_iteratively: load()'],
          ['info', 'group(user_id: user_123, group_id: group456, properties: {:some=>"data"})'],
          ['info', 'validate(event: #<Itly::Event: name: group, properties: {:some=>"data"}>)'],
          ['info', 'plugin_iteratively: post_group(user_id: user_123, group_id: group456, properties: #<Itly::Event: '\
                   'name: group, properties: {:some=>"data"}>, validation_results: [#<Itly::ValidationResponse: '\
                   'valid: true, plugin_id: test-plg, message: >])']
        ]
      end
    end

    context 'disabled' do
      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
          options.environment = Itly::Options::Environment::PRODUCTION
        end

        expect(plugin).not_to receive(:client_track)

        itly.group user_id: 'user_123', group_id: 'group456', properties: { some: 'data' }
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['info', 'plugin_iteratively: load()'],
          ['info', 'plugin_iteratively: plugin is disabled!'],
          ['info', 'group(user_id: user_123, group_id: group456, properties: {:some=>"data"})'],
          ['info', 'validate(event: #<Itly::Event: name: group, properties: {:some=>"data"}>)']
        ]
      end
    end

    context 'failure' do
      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
          options.environment = Itly::Options::Environment::DEVELOPMENT
        end

        expect(plugin.client).to receive(:track).and_raise('Testing')
      end

      it do
        expect do
          itly.group user_id: 'user_123', group_id: 'group456', properties: { some: 'data' }
        end.to raise_error(RuntimeError, 'Testing')
      end
    end
  end

  describe '#post_track' do
    let(:logs) { StringIO.new }
    let(:plugin) { Itly::PluginIteratively.new url: 'http://url', api_key: 'key123' }
    let(:track_event) { Itly::Event.new name: 'custom_event', properties: { custom: 'info' } }
    let(:itly) { Itly.new }

    context 'success' do
      let(:expected_event) { Itly::Event.new name: 'track', properties: { some: 'data' } }

      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
        end

        expect(plugin).to receive(:client_track).with('track', track_event, [])

        itly.track user_id: 'user_123', event: track_event
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['warn', 'Environment not specified. Automatically set to development'],
          ['info', 'plugin_iteratively: load()'],
          ['info', 'track(user_id: user_123, event: custom_event, properties: {:custom=>"info"})'],
          ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:custom=>"info"}>)'],
          ['info', 'plugin_iteratively: post_track(user_id: user_123, event: #<Itly::Event: '\
                    'name: custom_event, properties: {:custom=>"info"}>, validation_results: [])']
        ]
      end
    end

    context 'with validation messages' do
      let(:expected_event) { Itly::Event.new name: 'track', properties: { some: 'data' } }
      let(:response) { Itly::ValidationResponse.new valid: true, plugin_id: 'test-plg' }
      let(:validator) { Itly::Plugin.new }

      before do
        expect(validator).to receive(:validate).once.with(event: track_event).and_return(response)
        expect(validator).not_to receive(:validate)

        itly.load do |options|
          options.plugins = [plugin, validator]
          options.logger = ::Logger.new logs
        end

        expect(plugin).to receive(:client_track).with('track', track_event, [response])

        itly.track user_id: 'user_123', event: track_event
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['warn', 'Environment not specified. Automatically set to development'],
          ['info', 'plugin_iteratively: load()'],
          ['info', 'track(user_id: user_123, event: custom_event, properties: {:custom=>"info"})'],
          ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:custom=>"info"}>)'],
          ['info', 'plugin_iteratively: post_track(user_id: user_123, event: #<Itly::Event: '\
                   'name: custom_event, properties: {:custom=>"info"}>, validation_results: '\
                   '[#<Itly::ValidationResponse: valid: true, plugin_id: test-plg, message: >])']
        ]
      end
    end

    context 'disabled' do
      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
          options.environment = Itly::Options::Environment::PRODUCTION
        end

        expect(plugin).not_to receive(:client_track)

        itly.track user_id: 'user_123', event: track_event
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['info', 'plugin_iteratively: load()'],
          ['info', 'plugin_iteratively: plugin is disabled!'],
          ['info', 'track(user_id: user_123, event: custom_event, properties: {:custom=>"info"})'],
          ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:custom=>"info"}>)']
        ]
      end
    end

    context 'failure' do
      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
          options.environment = Itly::Options::Environment::DEVELOPMENT
        end

        expect(plugin.client).to receive(:track).and_raise('Testing')
      end

      it do
        expect do
          itly.track user_id: 'user_123', event: track_event
        end.to raise_error(RuntimeError, 'Testing')
      end
    end
  end

  describe '#enabled?' do
    let(:plugin) { Itly::PluginIteratively.new url: 'http://url', api_key: 'key123' }

    context 'disabled' do
      before do
        plugin.instance_variable_set '@disabled', true
      end

      it do
        expect(plugin.send(:enabled?)).to be(false)
      end
    end

    context 'enabled' do
      before do
        plugin.instance_variable_set '@disabled', false
      end

      it do
        expect(plugin.send(:enabled?)).to be(true)
      end
    end
  end

  describe '#client_track' do
    let(:event) { Itly::Event.new name: 'an_event', properties: { some: 'data' } }
    let(:plugin) { Itly::PluginIteratively.new url: 'http://url', api_key: 'key123' }

    before do
      plugin.instance_variable_set '@client', client
    end

    context 'validation is nil' do
      let(:client) { double 'client', track: nil }

      before do
        expect(client).to receive(:track)
          .with(type: 'event_type', properties: event, validation: nil)
      end

      it do
        plugin.send :client_track, 'event_type', event, nil
      end
    end

    context 'validation is empty' do
      let(:client) { double 'client', track: nil }

      before do
        expect(client).to receive(:track)
          .with(type: 'event_type', properties: event, validation: nil)
      end

      it do
        plugin.send :client_track, 'event_type', event, []
      end
    end

    context 'validations are valid' do
      let(:response1) { Itly::ValidationResponse.new valid: true, plugin_id: 'val1' }
      let(:response2) { Itly::ValidationResponse.new valid: true, plugin_id: 'val2' }
      let(:client) { double 'client', track: nil }

      before do
        expect(client).to receive(:track)
          .with(type: 'event_type', properties: event, validation: nil)
      end

      it do
        plugin.send :client_track, 'event_type', event, [response1, response2]
      end
    end

    context 'validation not valid' do
      let(:response1) { Itly::ValidationResponse.new valid: true, plugin_id: 'val1' }
      let(:response2) { Itly::ValidationResponse.new valid: false, plugin_id: 'val2' }
      let(:client) { double 'client', track: nil }

      before do
        expect(client).to receive(:track)
          .with(type: 'event_type', properties: event, validation: response2)
      end

      it do
        plugin.send :client_track, 'event_type', event, [response1, response2]
      end
    end
  end
end
