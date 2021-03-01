# frozen_string_literal: true

describe Itly::AmplitudePlugin do
  include RspecLoggerHelpers

  it 'register itself' do
    expect(Itly.registered_plugins).to eq([Itly::AmplitudePlugin])
  end

  describe 'instance attributes' do
    it 'can read' do
      expect(Itly::AmplitudePlugin.new.respond_to?(:logger)).to be(true)
    end

    it 'cannot write' do
      expect(Itly::AmplitudePlugin.new.respond_to?(:logger=)).to be(false)
    end
  end

  describe '#load' do
    let(:fake_logger) { double 'logger', info: nil }
    let(:itly) { Itly.new }

    before do
      itly.load do |options|
        options.plugins.amplitude_plugin = { api_key: 'key123' }
        options.logger = fake_logger
      end
    end

    let(:amplitude_plugin) { itly.instance_variable_get('@plugins_instances').first }

    it do
      expect(AmplitudeAPI.api_key).to eq('key123')
      expect(amplitude_plugin.logger).to eq(fake_logger)
    end
  end

  describe '#identify' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }

    before do
      itly.load { |o| o.logger = ::Logger.new logs }

      expect(AmplitudeAPI).to receive(:send_identify)
        .with('user_123', nil, version: '4', some: 'data')
        .and_return(response)

      itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
    end

    context 'success' do
      let(:response) { double 'response', status: 200 }

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['info', 'amplitude_plugin: load()'],
          ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})'],
          ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
          ['info', 'amplitude_plugin: identify(user_id: user_123, properties: #<Itly::Event: name: identify, '\
                   'properties: {:version=>"4", :some=>"data"}>)']
        ]
      end
    end

    context 'failure' do
      let(:response) { double 'response', status: 500, body: 'wrong params' }

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['info', 'amplitude_plugin: load()'],
          ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})'],
          ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
          ['info', 'amplitude_plugin: identify(user_id: user_123, properties: #<Itly::Event: name: identify, '\
                   'properties: {:version=>"4", :some=>"data"}>)'],
          ['error', 'Itly Error in Itly::AmplitudePlugin. Itly::RemoteError: The remote end-point returned an error. '\
                    'Response status: 500. Raw body: wrong params']
        ]
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
          ['info', 'amplitude_plugin: load()'],
          ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
          ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
          ['info', 'amplitude_plugin: track(user_id: user_123, event: custom_event, properties: {:view=>"video"})']
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

          options.context = {app_version: '1.2.3'}
        end
        itly.track user_id: 'user_123', event: event
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['info', 'amplitude_plugin: load()'],
          ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
          ['info', 'validate(event: #<Itly::Event: name: context, properties: {:app_version=>"1.2.3"}>)'],
          ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
          ['info', 'amplitude_plugin: track(user_id: user_123, event: custom_event, properties: {:view=>"video", :app_version=>"1.2.3"})']
        ]
      end
    end

    context 'failure' do
      let(:response) { double 'response', status: 500, body: 'wrong params' }

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
          ['info', 'amplitude_plugin: load()'],
          ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
          ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
          ['info', 'amplitude_plugin: track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
          ['error', 'Itly Error in Itly::AmplitudePlugin. Itly::RemoteError: The remote end-point returned an error. '\
                    'Response status: 500. Raw body: wrong params']
        ]
      end
    end
  end

  describe '#call_end_point' do
    let(:plugin) { Itly::AmplitudePlugin.new }

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
