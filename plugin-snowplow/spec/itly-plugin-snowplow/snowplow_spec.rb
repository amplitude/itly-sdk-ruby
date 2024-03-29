# frozen_string_literal: true

describe Itly::Plugin::Snowplow do
  include RspecLoggerHelpers

  describe 'instance attributes' do
    let(:plugin_options) { Itly::Plugin::Snowplow::Options.new endpoint: 'endpoint123' }
    let(:plugin) { Itly::Plugin::Snowplow.new vendor: 'vnd_name', options: plugin_options }

    it 'can read' do
      expect(plugin.respond_to?(:logger)).to be(true)
      expect(plugin.respond_to?(:vendor)).to be(true)
      expect(plugin.respond_to?(:disabled)).to be(true)
      expect(plugin.respond_to?(:client)).to be(true)
    end

    it 'cannot write' do
      expect(plugin.respond_to?(:logger=)).to be(false)
      expect(plugin.respond_to?(:vendor=)).to be(false)
      expect(plugin.respond_to?(:disabled=)).to be(false)
      expect(plugin.respond_to?(:client=)).to be(false)
    end
  end

  describe '#initialize' do
    let(:emitter) { double 'emitter' }
    let(:client) { double 'client' }

    describe 'default values' do
      let(:plugin_options) { Itly::Plugin::Snowplow::Options.new endpoint: 'endpoint123' }
      let(:plugin) { Itly::Plugin::Snowplow.new vendor: 'vnd_name', options: plugin_options }

      before do
        expect(SnowplowTracker::Emitter).to receive(:new)
          .with({ endpoint: 'endpoint123', options: { protocol: 'http', method: 'get', buffer_size: nil } })
          .and_return(emitter)
        expect(SnowplowTracker::Tracker).to receive(:new).with({ emitters: emitter }).and_return(client)
      end

      it do
        expect(plugin.vendor).to eq('vnd_name')
        expect(plugin.disabled).to be(false)
        expect(plugin.client).to eq(client)
      end
    end

    describe 'with values' do
      let(:plugin_options) do
        Itly::Plugin::Snowplow::Options.new \
          endpoint: 'endpoint123', protocol: 'https',
          method: 'post', buffer_size: 50, disabled: true
      end
      let(:plugin) { Itly::Plugin::Snowplow.new vendor: 'vnd_name', options: plugin_options }

      before do
        expect(SnowplowTracker::Emitter).to receive(:new)
          .with({ endpoint: 'endpoint123', options: { protocol: 'https', method: 'post', buffer_size: 50 } })
          .and_return(emitter)
        expect(SnowplowTracker::Tracker).to receive(:new).with({ emitters: emitter }).and_return(client)
      end

      it do
        expect(plugin.vendor).to eq('vnd_name')
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
      let(:plugin_options) { Itly::Plugin::Snowplow::Options.new endpoint: 'endpoint123' }
      let(:plugin) { Itly::Plugin::Snowplow.new vendor: 'vnd_name', options: plugin_options }

      it do
        expect(plugin.logger).to eq(logger)
      end
    end

    describe 'logging' do
      context 'enabled' do
        let(:plugin_options) { Itly::Plugin::Snowplow::Options.new endpoint: 'endpoint123' }
        let(:plugin) { Itly::Plugin::Snowplow.new vendor: 'vnd_name', options: plugin_options }

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'snowplow: load()']
          ]
        end
      end

      context 'disabled' do
        let(:plugin_options) do
          Itly::Plugin::Snowplow::Options.new endpoint: 'endpoint123', disabled: true
        end
        let(:plugin) { Itly::Plugin::Snowplow.new vendor: 'vnd_name', options: plugin_options }

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'snowplow: load()'],
            ['info', 'snowplow: plugin is disabled!']
          ]
        end
      end
    end
  end

  describe '#identify' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }

    describe 'enabled' do
      let(:plugin_options) { Itly::Plugin::Snowplow::Options.new endpoint: 'endpoint123' }
      let(:plugin) { Itly::Plugin::Snowplow.new vendor: 'vnd_name', options: plugin_options }

      context 'success' do
        before do
          expect(plugin.client).to receive(:set_user_id).with('user_123')
        end

        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
          end

          itly.identify user_id: 'user_123', properties: { ignored: 'data' }
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'snowplow: load()'],
            ['info', 'identify(user_id: user_123, properties: {:ignored=>"data"})'],
            ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:ignored=>"data"}>)'],
            ['info', 'snowplow: identify(user_id: user_123)']
          ]
        end
      end

      context 'failure' do
        before do
          expect(plugin.client).to receive(:set_user_id).with('user_123')
            .and_raise('Test rspec')
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
              itly.identify user_id: 'user_123', properties: { ignored: 'data' }
            end.to raise_error(RuntimeError, 'Test rspec')
          end
        end

        context 'production' do
          before do
            itly.load do |options|
              options.plugins = [plugin]
              options.logger = ::Logger.new logs
              options.environment = Itly::Options::Environment::PRODUCTION
            end

            itly.identify user_id: 'user_123', properties: { ignored: 'data' }
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'snowplow: load()'],
              ['info', 'identify(user_id: user_123, properties: {:ignored=>"data"})'],
              ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:ignored=>"data"}>)'],
              ['info', 'snowplow: identify(user_id: user_123)'],
              ['error', 'Itly Error in Itly::Plugin::Snowplow. RuntimeError: Test rspec']
            ]
          end
        end
      end
    end

    context 'disabled' do
      let(:plugin_options) do
        Itly::Plugin::Snowplow::Options.new endpoint: 'endpoint123', disabled: true
      end
      let(:plugin) { Itly::Plugin::Snowplow.new vendor: 'vnd_name', options: plugin_options }

      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
        end

        expect(plugin.client).not_to receive(:set_user_id)
      end

      it do
        itly.identify user_id: 'user_123', properties: { ignored: 'data' }
      end
    end
  end

  describe '#page' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }

    describe 'enabled' do
      let(:plugin_options) { Itly::Plugin::Snowplow::Options.new endpoint: 'endpoint123' }
      let(:plugin) { Itly::Plugin::Snowplow.new vendor: 'vnd_name', options: plugin_options }

      context 'success' do
        before do
          expect(plugin.client).to receive(:set_user_id).with('user_123')
        end

        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
          end

          itly.page user_id: 'user_123', category: 'Prd', name: 'pageABC', properties: { ignored: 'data' }
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'snowplow: load()'],
            ['info', 'page(user_id: user_123, category: Prd, name: pageABC, properties: {:ignored=>"data"})'],
            ['info', 'validate(event: #<Itly::Event: name: page, properties: {:ignored=>"data"}>)'],
            ['info', 'snowplow: page(user_id: user_123, category: Prd, name: pageABC, properties: {:ignored=>"data"})']
          ]
        end
      end

      context 'failure' do
        before do
          expect(plugin.client).to receive(:set_user_id).with('user_123')
            .and_raise('Test rspec')
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
              itly.page user_id: 'user_123', category: 'Prd', name: 'pageABC', properties: { ignored: 'data' }
            end.to raise_error(RuntimeError, 'Test rspec')
          end
        end

        context 'production' do
          before do
            itly.load do |options|
              options.plugins = [plugin]
              options.logger = ::Logger.new logs
              options.environment = Itly::Options::Environment::PRODUCTION
            end

            itly.page user_id: 'user_123', category: 'Prd', name: 'pageABC', properties: { ignored: 'data' }
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'snowplow: load()'],
              ['info', 'page(user_id: user_123, category: Prd, name: pageABC, properties: {:ignored=>"data"})'],
              ['info', 'validate(event: #<Itly::Event: name: page, properties: {:ignored=>"data"}>)'],
              ['info', 'snowplow: page(user_id: user_123, category: Prd, name: pageABC, '\
                       'properties: {:ignored=>"data"})'],
              ['error', 'Itly Error in Itly::Plugin::Snowplow. RuntimeError: Test rspec']
            ]
          end
        end
      end
    end

    context 'disabled' do
      let(:plugin_options) do
        Itly::Plugin::Snowplow::Options.new endpoint: 'endpoint123', disabled: true
      end
      let(:plugin) { Itly::Plugin::Snowplow.new vendor: 'vnd_name', options: plugin_options }

      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
        end

        expect(plugin.client).not_to receive(:set_user_id)
      end

      it do
        itly.page user_id: 'user_123', category: 'Prd', name: 'pageABC', properties: { ignored: 'data' }
      end
    end
  end

  describe '#track' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }
    let(:event) { Itly::Event.new name: 'custom_event', version: '1.2.3', properties: { view: 'video' } }

    describe 'enabled' do
      let(:plugin_options) { Itly::Plugin::Snowplow::Options.new endpoint: 'endpoint123' }
      let(:plugin) { Itly::Plugin::Snowplow.new vendor: 'vnd_name', options: plugin_options }

      let(:json1) do
        SnowplowTracker::SelfDescribingJson.new \
          'iglu:vnd_name/custom_event/jsonschema/1-2-3', view: 'video'
      end

      before do
        expect(plugin.client).to receive(:set_user_id).with('user_123')
      end

      context 'success' do
        before do
          expect(plugin.client).to receive(:track_self_describing_event)
            .with({ event_json: json1, context: nil })

          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
          end

          itly.track user_id: 'user_123', event: event
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'snowplow: load()'],
            ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
            ['info', 'validate(event: #<Itly::Event: name: custom_event, version: 1.2.3, ' \
                     'properties: {:view=>"video"}>)'],
            ['info', 'snowplow: track(user_id: user_123, event: custom_event, '\
                     'version: 1.2.3, properties: {:view=>"video"})']
          ]
        end
      end

      context 'with contexts' do
        let!(:context1) { Itly::Plugin::Snowplow::Context.new schema: '123', data: { 'cntx' => 1 } }
        let!(:context2) { Itly::Plugin::Snowplow::Context.new schema: '456', data: { 'cntx' => 2 } }

        let(:json2) { SnowplowTracker::SelfDescribingJson.new '123', 'cntx' => 1 }
        let(:json3) { SnowplowTracker::SelfDescribingJson.new '456', 'cntx' => 2 }

        before do
          expect(plugin.client).to receive(:track_self_describing_event)
            .with({ event_json: json1, context: [json2, json3] })

          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
          end

          itly.track(
            user_id: 'user_123', event: event,
            options: { 'snowplow' => Itly::Plugin::Snowplow::TrackOptions.new(
              contexts: [context1, context2]
            ) }
          )
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'snowplow: load()'],
            ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"}, options: '\
                     '{"snowplow"=>#<Snowplow::TrackOptions contexts: [#<Snowplow::Context schema: 123 '\
                     'data: {"cntx"=>1}>, #<Snowplow::Context schema: 456 data: {"cntx"=>2}>] callback: nil>})'],
            ['info', 'validate(event: #<Itly::Event: name: custom_event, version: 1.2.3, ' \
                     'properties: {:view=>"video"}>)'],
            ['info', 'snowplow: track(user_id: user_123, event: custom_event, '\
                     'version: 1.2.3, properties: {:view=>"video"}, options: #<Snowplow::TrackOptions '\
                     'contexts: [#<Snowplow::Context schema: 123 data: {"cntx"=>1}>, #<Snowplow::Context '\
                     'schema: 456 data: {"cntx"=>2}>] callback: nil>)']
          ]
        end
      end

      context 'failure' do
        before do
          expect(plugin.client).to receive(:track_self_describing_event)
            .with({ event_json: json1, context: nil })
            .and_raise('Test rspec')
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
            end.to raise_error(RuntimeError, 'Test rspec')
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
              ['info', 'snowplow: load()'],
              ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
              ['info', 'validate(event: #<Itly::Event: name: custom_event, version: 1.2.3, ' \
                       'properties: {:view=>"video"}>)'],
              ['info', 'snowplow: track(user_id: user_123, event: custom_event, '\
                       'version: 1.2.3, properties: {:view=>"video"})'],
              ['error', 'Itly Error in Itly::Plugin::Snowplow. RuntimeError: Test rspec']
            ]
          end
        end
      end
    end

    context 'disabled' do
      let(:plugin_options) do
        Itly::Plugin::Snowplow::Options.new endpoint: 'endpoint123', disabled: true
      end
      let(:plugin) { Itly::Plugin::Snowplow.new vendor: 'vnd_name', options: plugin_options }

      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
        end

        expect(plugin.client).not_to receive(:set_user_id)
        expect(plugin.client).not_to receive(:track_self_describing_event)
      end

      it do
        itly.track user_id: 'user_123', event: event
      end
    end
  end

  describe '#enabled?' do
    describe 'enabled' do
      let(:plugin_options) { Itly::Plugin::Snowplow::Options.new endpoint: 'endpoint123' }
      let(:plugin) { Itly::Plugin::Snowplow.new vendor: 'vnd_name', options: plugin_options }

      it do
        expect(plugin.send(:enabled?)).to be(true)
      end
    end

    describe 'disabled' do
      let(:plugin_options) do
        Itly::Plugin::Snowplow::Options.new endpoint: 'endpoint123', disabled: true
      end
      let(:plugin) { Itly::Plugin::Snowplow.new vendor: 'vnd_name', options: plugin_options }

      it do
        expect(plugin.send(:enabled?)).to be(false)
      end
    end
  end
end
