# frozen_string_literal: true

describe Itly::PluginAmplitude do
  include RspecLoggerHelpers

  it 'register itself' do
    expect(Itly.registered_plugins).to eq([Itly::PluginAmplitude])
  end

  describe 'instance attributes' do
    it 'can read' do
      expect(Itly::PluginAmplitude.new.respond_to?(:logger)).to be(true)
    end

    it 'cannot write' do
      expect(Itly::PluginAmplitude.new.respond_to?(:logger=)).to be(false)
    end
  end

  describe '#load' do
    let(:fake_logger) { double 'logger', info: nil, warn: nil }
    let(:itly) { Itly.new }

    before do
      itly.load do |options|
        options.plugins.amplitude = { api_key: 'key123' }
        options.logger = fake_logger
      end
    end

    let(:plugin_amplitude) { itly.instance_variable_get('@plugins_instances').first }

    it do
      expect(AmplitudeAPI.api_key).to eq('key123')
      expect(plugin_amplitude.logger).to eq(fake_logger)
    end
  end

  describe '#identify' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }

    before do
      expect(AmplitudeAPI).to receive(:send_identify)
        .with('user_123', nil, version: '4', some: 'data')
        .and_return(response)
    end

    context 'success' do
      let(:response) { double 'response', status: 200 }

      before do
        itly.load { |o| o.logger = ::Logger.new logs }

        itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['warn', 'Environment not specified. Automatically set to development'],
          ['info', 'plugin_amplitude: load()'],
          ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})'],
          ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
          ['info', 'plugin_amplitude: identify(user_id: user_123, properties: #<Itly::Event: name: identify, '\
                   'properties: {:version=>"4", :some=>"data"}>)']
        ]
      end
    end

    context 'failure' do
      let(:response) { double 'response', status: 500, body: 'wrong params' }

      context 'development' do
        before do
          itly.load do |options|
            options.logger = ::Logger.new logs
            options.environment = Itly::Options::Environment::DEVELOPMENT
          end
        end

        it do
          expect do
            itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
          end.to raise_error(Itly::RemoteError, 'The remote end-point returned an error. '\
            'Response status: 500. Raw body: wrong params')
        end
      end

      context 'production' do
        before do
          itly.load do |options|
            options.logger = ::Logger.new logs
            options.environment = Itly::Options::Environment::PRODUCTION
          end

          itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'plugin_amplitude: load()'],
            ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})'],
            ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
            ['info', 'plugin_amplitude: identify(user_id: user_123, properties: #<Itly::Event: name: identify, '\
                     'properties: {:version=>"4", :some=>"data"}>)'],
            ['error', 'Itly Error in Itly::PluginAmplitude. Itly::RemoteError: The remote end-point returned an error. '\
                      'Response status: 500. Raw body: wrong params']
          ]
        end
      end
    end
  end

  describe '#track' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }
    let(:event) { Itly::Event.new name: 'custom_event', properties: { view: 'video' } }

    context 'success' do
      let(:response) { double 'response', status: 200 }

      before do
        itly.load { |o| o.logger = ::Logger.new logs }

        expect(AmplitudeAPI).to receive(:send_event)
          .with('custom_event', 'user_123', nil, event_properties: { view: 'video' })
          .and_return(response)

        itly.track user_id: 'user_123', event: event
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['warn', 'Environment not specified. Automatically set to development'],
          ['info', 'plugin_amplitude: load()'],
          ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
          ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
          ['info', 'plugin_amplitude: track(user_id: user_123, event: custom_event, properties: {:view=>"video"})']
        ]
      end
    end

    context 'with context' do
      let(:response) { double 'response', status: 200 }

      before do
        itly.load do |options|
          options.logger = ::Logger.new logs

          expect(AmplitudeAPI).to receive(:send_event)
            .with('custom_event', 'user_123', nil, event_properties: { app_version: '1.2.3', view: 'video' })
            .and_return(response)

          options.context = { app_version: '1.2.3' }
        end
        itly.track user_id: 'user_123', event: event
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['warn', 'Environment not specified. Automatically set to development'],
          ['info', 'plugin_amplitude: load()'],
          ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
          ['info', 'validate(event: #<Itly::Event: name: context, properties: {:app_version=>"1.2.3"}>)'],
          ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
          ['info', 'plugin_amplitude: track(user_id: user_123, event: custom_event, properties: '\
                   '{:view=>"video", :app_version=>"1.2.3"})']
        ]
      end
    end

    context 'failure' do
      let(:response) { double 'response', status: 500, body: 'wrong params' }

      before do
        expect(AmplitudeAPI).to receive(:send_event)
          .with('custom_event', 'user_123', nil, event_properties: { view: 'video' })
          .and_return(response)
      end

      context 'development' do
        before do
          itly.load do |options|
            options.logger = ::Logger.new logs
            options.environment = Itly::Options::Environment::DEVELOPMENT
          end
        end

        it do
          expect do
            itly.track user_id: 'user_123', event: event
          end.to raise_error(Itly::RemoteError, 'The remote end-point returned an error. '\
            'Response status: 500. Raw body: wrong params')
        end
      end

      context 'production' do
        before do
          itly.load do |options|
            options.logger = ::Logger.new logs
            options.environment = Itly::Options::Environment::PRODUCTION
          end

          itly.track user_id: 'user_123', event: event
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'plugin_amplitude: load()'],
            ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
            ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
            ['info', 'plugin_amplitude: track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
            ['error', 'Itly Error in Itly::PluginAmplitude. Itly::RemoteError: The remote end-point returned an error. '\
                      'Response status: 500. Raw body: wrong params']
          ]
        end
      end
    end
  end

  describe '#call_end_point' do
    let(:plugin) { Itly::PluginAmplitude.new }

    it 'no block given' do
      expect { plugin.send :call_end_point }.to raise_error(RuntimeError, 'You need to give a block')
    end

    describe 'respond 200' do
      let(:response) { double 'response', status: 200 }

      it do
        expect do
          plugin.send(:call_end_point) { response }
        end.not_to raise_error
      end
    end

    describe 'respond 500' do
      let(:response) { double 'response', status: 500, body: 'remote message' }

      it do
        expect do
          plugin.send(:call_end_point) { response }
        end.to raise_error(Itly::RemoteError,
          'The remote end-point returned an error. Response status: 500. Raw body: remote message')
      end
    end
  end
end
