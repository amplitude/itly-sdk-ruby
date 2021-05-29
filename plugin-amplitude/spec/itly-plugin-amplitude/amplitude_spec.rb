# frozen_string_literal: true

describe Itly::Plugin::Amplitude do
  include RspecLoggerHelpers

  describe 'instance attributes' do
    let(:plugin) { Itly::Plugin::Amplitude.new api_key: 'abc123' }

    it 'can read' do
      expect(plugin.respond_to?(:logger)).to be(true)
      expect(plugin.respond_to?(:disabled)).to be(true)
    end

    it 'cannot write' do
      expect(plugin.respond_to?(:logger=)).to be(false)
      expect(plugin.respond_to?(:disabled=)).to be(false)
    end
  end

  describe '#initialize' do
    describe 'default values' do
      let!(:plugin) { Itly::Plugin::Amplitude.new api_key: 'key123' }

      it do
        expect(AmplitudeAPI.api_key).to eq('key123')
        expect(plugin.disabled).to be(false)
      end
    end

    describe 'with values' do
      let!(:plugin) { Itly::Plugin::Amplitude.new api_key: 'key123', disabled: true }

      it do
        expect(AmplitudeAPI.api_key).to eq('key123')
        expect(plugin.disabled).to be(true)
      end
    end
  end

  describe '#load' do
    let(:logs) { StringIO.new }
    let(:logger) { Logger.new logs }
    let(:itly) { Itly.new }

    before do
      itly.load do |options|
        options.plugins = [plugin]
        options.logger = logger
      end
    end

    describe 'pass values from the itly object' do
      let(:plugin) { Itly::Plugin::Amplitude.new api_key: 'key123' }

      it do
        expect(plugin.logger).to eq(logger)
      end
    end

    describe 'logging' do
      context 'enabled' do
        let(:plugin) { Itly::Plugin::Amplitude.new api_key: 'key123' }

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'amplitude: load()']
          ]
        end
      end

      context 'disabled' do
        let(:plugin) { Itly::Plugin::Amplitude.new api_key: 'key123', disabled: true }

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'amplitude: load()'],
            ['info', 'amplitude: plugin is disabled!']
          ]
        end
      end
    end
  end

  describe '#identify' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }

    describe 'enabled' do
      let(:plugin) { Itly::Plugin::Amplitude.new api_key: 'key123' }

      before do
        expect(AmplitudeAPI).to receive(:send_identify)
          .with('user_123', nil, version: '4', some: 'data')
          .and_return(response)
      end

      context 'success' do
        let(:response) { double 'response', status: 200 }

        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
          end

          itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'amplitude: load()'],
            ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})'],
            ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
            ['info', 'amplitude: identify(user_id: user_123, properties: {:version=>"4", :some=>"data"}, '\
                     'options: )']
          ]
        end
      end

      context 'with callback' do
        let(:response) { double 'response', status: 201, body: 'raw data' }
        let(:logger) { ::Logger.new logs }

        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = logger
          end

          itly.identify(
            user_id: 'user_123', properties: { version: '4', some: 'data' },
            options: { 'amplitude' => Itly::Plugin::Amplitude::IdentifyOptions.new(
              callback: ->(code, body) { logger.info "from-callback: code: #{code} body: #{body}" }
            ) }
          )
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'amplitude: load()'],
            ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})'],
            ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
            ['info', 'amplitude: identify(user_id: user_123, properties: {:version=>"4", :some=>"data"}, '\
                     'options: #<Amplitude::IdentifyOptions callback: provided>)'],
            ['info', 'from-callback: code: 201 body: raw data']

          ]
        end
      end

      context 'failure' do
        let(:response) { double 'response', status: 500, body: 'wrong params' }

        context 'development' do
          before do
            itly.load do |options|
              options.plugins = [plugin]
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
              options.plugins = [plugin]
              options.logger = ::Logger.new logs
              options.environment = Itly::Options::Environment::PRODUCTION
            end

            itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'amplitude: load()'],
              ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})'],
              ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
              ['info', 'amplitude: identify(user_id: user_123, properties: {:version=>"4", :some=>"data"}, '\
                       'options: )'],
              ['error', 'Itly Error in Itly::Plugin::Amplitude. Itly::RemoteError: The remote end-point returned an '\
                        'error. Response status: 500. Raw body: wrong params']
            ]
          end
        end
      end
    end

    context 'disabled' do
      let(:plugin) { Itly::Plugin::Amplitude.new api_key: 'key123', disabled: true }

      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
        end

        expect(AmplitudeAPI).not_to receive(:send_identify)
      end

      it do
        itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
      end
    end
  end

  describe '#track' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }
    let(:event) { Itly::Event.new name: 'custom_event', properties: { view: 'video' } }

    describe 'enabled' do
      let(:plugin) { Itly::Plugin::Amplitude.new api_key: 'key123' }

      context 'success' do
        let(:response) { double 'response', status: 200 }

        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
          end

          expect(AmplitudeAPI).to receive(:send_event)
            .with('custom_event', 'user_123', nil, event_properties: { view: 'video' })
            .and_return(response)

          itly.track user_id: 'user_123', event: event
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'amplitude: load()'],
            ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
            ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
            ['info', 'amplitude: track(user_id: user_123, event: custom_event, properties: {:view=>"video"}, '\
                     'options: )']
          ]
        end
      end

      context 'with callback' do
        let(:response) { double 'response', status: 201, body: 'raw data' }
        let(:logger) { ::Logger.new logs }

        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = logger
          end

          expect(AmplitudeAPI).to receive(:send_event)
            .with('custom_event', 'user_123', nil, event_properties: { view: 'video' })
            .and_return(response)

          itly.track(
            user_id: 'user_123', event: event,
            options: { 'amplitude' => Itly::Plugin::Amplitude::TrackOptions.new(
              callback: ->(code, body) { logger.info "from-callback: code: #{code} body: #{body}" }
            ) }
          )
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'amplitude: load()'],
            ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
            ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
            ['info', 'amplitude: track(user_id: user_123, event: custom_event, properties: {:view=>"video"}, '\
                     'options: #<Amplitude::TrackOptions callback: provided>)'],
            ['info', 'from-callback: code: 201 body: raw data']
          ]
        end
      end

      context 'with context' do
        let(:response) { double 'response', status: 200 }

        before do
          itly.load(context: { app_version: '1.2.3' }) do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
          end

          expect(AmplitudeAPI).to receive(:send_event)
            .with('custom_event', 'user_123', nil, event_properties: { app_version: '1.2.3', view: 'video' })
            .and_return(response)

          itly.track user_id: 'user_123', event: event
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'amplitude: load()'],
            ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
            ['info', 'validate(event: #<Itly::Event: name: context, properties: {:app_version=>"1.2.3"}>)'],
            ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
            ['info', 'amplitude: track(user_id: user_123, event: custom_event, properties: '\
                    '{:view=>"video", :app_version=>"1.2.3"}, options: )']
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
              options.plugins = [plugin]
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
              options.plugins = [plugin]
              options.logger = ::Logger.new logs
              options.environment = Itly::Options::Environment::PRODUCTION
            end

            itly.track user_id: 'user_123', event: event
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'amplitude: load()'],
              ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
              ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
              ['info', 'amplitude: track(user_id: user_123, event: custom_event, properties: {:view=>"video"}, '\
                       'options: )'],
              ['error', 'Itly Error in Itly::Plugin::Amplitude. Itly::RemoteError: The remote end-point returned an '\
                        'error. Response status: 500. Raw body: wrong params']
            ]
          end
        end
      end
    end

    context 'disabled' do
      let(:plugin) { Itly::Plugin::Amplitude.new api_key: 'key123', disabled: true }

      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
        end

        expect(AmplitudeAPI).not_to receive(:send_event)
      end

      it do
        itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
      end
    end
  end

  describe '#enabled?' do
    describe 'enabled' do
      let(:plugin) { Itly::Plugin::Amplitude.new api_key: 'key123' }

      it do
        expect(plugin.send(:enabled?)).to be(true)
      end
    end

    describe 'disabled' do
      let(:plugin) { Itly::Plugin::Amplitude.new api_key: 'key123', disabled: true }

      it do
        expect(plugin.send(:enabled?)).to be(false)
      end
    end
  end

  describe '#call_end_point' do
    let(:plugin) { Itly::Plugin::Amplitude.new api_key: 'abc123' }

    it 'no block given' do
      expect { plugin.send :call_end_point, nil }.to raise_error(RuntimeError, 'You need to give a block')
    end

    describe 'respond 200' do
      let(:response) { double 'response', status: 200 }

      it do
        expect do
          plugin.send(:call_end_point, nil) { response }
        end.not_to raise_error
      end
    end

    describe 'respond 500' do
      let(:response) { double 'response', status: 500, body: 'remote message' }

      it do
        expect do
          plugin.send(:call_end_point, nil) { response }
        end.to raise_error(Itly::RemoteError,
          'The remote end-point returned an error. Response status: 500. Raw body: remote message')
      end
    end

    describe 'with a callback' do
      let(:cb_tester) { double 'cb', tester: nil }
      let(:response) { double 'response', status: 200, body: 'response from endpoint' }

      before do
        expect(cb_tester).to receive(:tester).with(200, 'response from endpoint')
      end

      it do
        expect do
          plugin.send(
            :call_end_point,
            ->(a, b) { cb_tester.tester a, b }
          ) { response }
        end.not_to raise_error
      end
    end
  end
end
