# frozen_string_literal: true

describe Itly::Plugin::Snowplow do
  include RspecLoggerHelpers

  describe 'instance attributes' do
    let(:plugin) { Itly::Plugin::Snowplow.new endpoint: 'endpoint123', vendor: 'vnd_name' }

    it 'can read' do
      expect(plugin.respond_to?(:logger)).to be(true)
      expect(plugin.respond_to?(:vendor)).to be(true)
      expect(plugin.respond_to?(:disabled)).to be(true)
      expect(plugin.respond_to?(:tracker)).to be(true)
    end

    it 'cannot write' do
      expect(plugin.respond_to?(:logger=)).to be(false)
      expect(plugin.respond_to?(:vendor=)).to be(false)
      expect(plugin.respond_to?(:disabled=)).to be(false)
      expect(plugin.respond_to?(:tracker=)).to be(false)
    end
  end

  describe '#initialize' do
    describe 'default values' do
      let!(:plugin) { Itly::Plugin::Snowplow.new endpoint: 'endpoint123', vendor: 'vnd_name' }

      it do
        expect(plugin.vendor).to eq('vnd_name')
        expect(plugin.disabled).to be(false)
      end
    end

    describe 'with values' do
      let!(:plugin) { Itly::Plugin::Snowplow.new endpoint: 'endpoint123', vendor: 'vnd_name', disabled: true }

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
      let(:plugin) { Itly::Plugin::Snowplow.new endpoint: 'endpoint123', vendor: 'vnd_name' }

      it do
        expect(plugin.logger).to eq(logger)
      end
    end

    describe 'logging' do
      context 'enabled' do
        let(:plugin) { Itly::Plugin::Snowplow.new endpoint: 'endpoint123', vendor: 'vnd_name' }

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['warn', 'Environment not specified. Automatically set to development'],
            ['info', 'plugin-snowplow: load()']
          ]
        end
      end

      context 'disabled' do
        let(:plugin) { Itly::Plugin::Snowplow.new endpoint: 'endpoint123', vendor: 'vnd_name', disabled: true }

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['warn', 'Environment not specified. Automatically set to development'],
            ['info', 'plugin-snowplow: load()'],
            ['info', 'plugin-snowplow: plugin is disabled!']
          ]
        end
      end
    end
  end

  describe '#identify' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }

    describe 'enabled' do
      let(:plugin) { Itly::Plugin::Snowplow.new endpoint: 'endpoint123', vendor: 'vnd_name' }

      context 'success' do
        before do
          expect(plugin.tracker).to receive(:set_user_id).with('user_123')
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
            ['warn', 'Environment not specified. Automatically set to development'],
            ['info', 'plugin-snowplow: load()'],
            ['info', 'identify(user_id: user_123, properties: {:ignored=>"data"})'],
            ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:ignored=>"data"}>)'],
            ['info', 'plugin-snowplow: identify(user_id: user_123)']
          ]
        end
      end

      context 'failure' do
        before do
          expect(plugin.tracker).to receive(:set_user_id).with('user_123')
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
              ['info', 'plugin-snowplow: load()'],
              ['info', 'identify(user_id: user_123, properties: {:ignored=>"data"})'],
              ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:ignored=>"data"}>)'],
              ['info', 'plugin-snowplow: identify(user_id: user_123)'],
              ['error', 'Itly Error in Itly::Plugin::Snowplow. RuntimeError: Test rspec']
            ]
          end
        end
      end
    end

    context 'disabled' do
      let(:plugin) { Itly::Plugin::Snowplow.new endpoint: 'endpoint123', vendor: 'vnd_name', disabled: true }

      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
        end

        expect(plugin.tracker).not_to receive(:set_user_id)
      end

      it do
        itly.identify user_id: 'user_123', properties: { ignored: 'data' }
      end
    end
  end

  describe '#track' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }
    let(:event) { Itly::Event.new name: 'custom_event', version: '1.2.3', properties: { view: 'video' } }

    describe 'enabled' do
      let(:plugin) { Itly::Plugin::Snowplow.new endpoint: 'endpoint123', vendor: 'vnd_name' }

      before do
        expect(SnowplowTracker::SelfDescribingJson).to receive(:new)
          .with('iglu:vnd_name/custom_event/jsonschema/1-2-3', view: 'video')
          .and_return('self_describing_json')
      end

      context 'success' do
        before do
          expect(plugin.tracker).to receive(:track_self_describing_event).with('self_describing_json')
        end

        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
          end

          itly.track user_id: 'user_123', event: event
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['warn', 'Environment not specified. Automatically set to development'],
            ['info', 'plugin-snowplow: load()'],
            ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
            ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
            ['info', 'plugin-snowplow: track(user_id: user_123, event: custom_event, '\
                     'version: 1.2.3, properties: {:view=>"video"})']
          ]
        end
      end

      context 'failure' do
        before do
          expect(plugin.tracker).to receive(:track_self_describing_event).with('self_describing_json')
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
              ['info', 'plugin-snowplow: load()'],
              ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
              ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
              ['info', 'plugin-snowplow: track(user_id: user_123, event: custom_event, '\
                       'version: 1.2.3, properties: {:view=>"video"})'],
              ['error', 'Itly Error in Itly::Plugin::Snowplow. RuntimeError: Test rspec']
            ]
          end
        end
      end
    end

    context 'disabled' do
      let(:plugin) { Itly::Plugin::Snowplow.new endpoint: 'endpoint123', vendor: 'vnd_name', disabled: true }

      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
        end

        expect(plugin.tracker).not_to receive(:track_self_describing_event)
      end

      it do
        itly.track user_id: 'user_123', event: event
      end
    end
  end

  describe '#enabled?' do
    describe 'enabled' do
      let(:plugin) { Itly::Plugin::Snowplow.new endpoint: 'endpoint123', vendor: 'vnd_name' }

      it do
        expect(plugin.send(:enabled?)).to be(true)
      end
    end

    describe 'disabled' do
      let(:plugin) { Itly::Plugin::Snowplow.new endpoint: 'endpoint123', vendor: 'vnd_name', disabled: true }

      it do
        expect(plugin.send(:enabled?)).to be(false)
      end
    end
  end
end