# frozen_string_literal: true

describe Itly::PluginSegment do
  include RspecLoggerHelpers

  describe 'instance attributes' do
    let(:plugin) { Itly::PluginSegment.new write_key: 'abc123' }

    it 'can read' do
      expect(plugin.respond_to?(:logger)).to be(true)
      expect(plugin.respond_to?(:client)).to be(true)
      expect(plugin.respond_to?(:write_key)).to be(true)
    end

    it 'cannot write' do
      expect(plugin.respond_to?(:logger=)).to be(false)
      expect(plugin.respond_to?(:client=)).to be(false)
      expect(plugin.respond_to?(:write_key=)).to be(false)
    end
  end

  describe '#load' do
    let(:fake_logger) { double 'logger', info: nil, warn: nil }
    let(:itly) { Itly.new }

    context 'single plugin' do
      let(:plugin) { Itly::PluginSegment.new write_key: 'key123' }

      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = fake_logger
        end
      end

      it do
        expect(plugin.client).to be_a_kind_of(::SimpleSegment::Client)
        expect(plugin.client.config.write_key).to eq('key123')
        expect(plugin.logger).to eq(fake_logger)
      end
    end

    context 'single plugin' do
      let(:plugin1) { Itly::PluginSegment.new write_key: 'key123' }
      let(:plugin2) { Itly::PluginSegment.new write_key: 'key456' }

      before do
        itly.load do |options|
          options.plugins = [plugin1, plugin2]
          options.logger = fake_logger
        end
      end

      it do
        expect(plugin1.client).to be_a_kind_of(::SimpleSegment::Client)
        expect(plugin2.client).to be_a_kind_of(::SimpleSegment::Client)
        expect(plugin1.client).not_to eq(plugin2.client)

        expect(plugin1.client.config.write_key).to eq('key123')
        expect(plugin2.client.config.write_key).to eq('key456')

        expect(plugin1.logger).to eq(fake_logger)
        expect(plugin2.logger).to eq(fake_logger)
      end
    end
  end

  describe '#identify' do
    let(:logs) { StringIO.new }
    let(:plugin) { Itly::PluginSegment.new write_key: 'key123' }
    let(:itly) { Itly.new }

    context 'success' do
      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
        end

        expect(plugin.client).to receive(:identify)
          .with(user_id: 'user_123', traits: { version: '4', some: 'data' })

        itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['warn', 'Environment not specified. Automatically set to development'],
          ['info', 'plugin_segment: load()'],
          ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})'],
          ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
          ['info', 'plugin_segment: identify(user_id: user_123, properties: #<Itly::Event: name: identify, '\
                   'properties: {:version=>"4", :some=>"data"}>)']
        ]
      end
    end

    context 'failure' do
      context 'development' do
        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
            options.environment = Itly::Options::Environment::DEVELOPMENT
          end

          expect(plugin.client).to receive(:identify)
            .with(user_id: 'user_123', traits: { version: '4', some: 'data' })
            .and_call_original

          stub_const 'SimpleSegment::Request::BASE_URL', 'not a url'
        end

        it do
          expect do
            itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
          end.to raise_error(Itly::RemoteError, 'The client returned an error. Exception '\
            'URI::InvalidURIError: bad URI(is not URI?): "not a url".')
        end
      end

      context 'production' do
        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
            options.environment = Itly::Options::Environment::PRODUCTION
          end

          expect(plugin.client).to receive(:identify)
            .with(user_id: 'user_123', traits: { version: '4', some: 'data' })
            .and_call_original

          stub_const 'SimpleSegment::Request::BASE_URL', 'not a url'

          itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'plugin_segment: load()'],
            ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})'],
            ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
            ['info', 'plugin_segment: identify(user_id: user_123, properties: #<Itly::Event: name: identify, '\
                    'properties: {:version=>"4", :some=>"data"}>)'],
            ['error', 'Itly Error in Itly::PluginSegment. Itly::RemoteError: The client returned an error. Exception '\
                      'URI::InvalidURIError: bad URI(is not URI?): "not a url".']
          ]
        end
      end
    end
  end

  describe '#group' do
    let(:logs) { StringIO.new }
    let(:plugin) { Itly::PluginSegment.new write_key: 'key123' }
    let(:itly) { Itly.new }

    context 'success' do
      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
        end

        expect(plugin.client).to receive(:group)
          .with(user_id: 'user_123', group_id: 'groupABC', traits: { active: 'yes' })

        itly.group user_id: 'user_123', group_id: 'groupABC', properties: { active: 'yes' }
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['warn', 'Environment not specified. Automatically set to development'],
          ['info', 'plugin_segment: load()'],
          ['info', 'group(user_id: user_123, group_id: groupABC, properties: {:active=>"yes"})'],
          ['info', 'validate(event: #<Itly::Event: name: group, properties: {:active=>"yes"}>)'],
          ['info', 'plugin_segment: group(user_id: user_123, group_id: groupABC, '\
                   'properties: #<Itly::Event: name: group, properties: {:active=>"yes"}>)']
        ]
      end
    end

    context 'failure' do
      context 'development' do
        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
            options.environment = Itly::Options::Environment::DEVELOPMENT
          end

          expect(plugin.client).to receive(:group)
            .with(user_id: 'user_123', group_id: 'groupABC', traits: { active: 'yes' })
            .and_call_original

          stub_const 'SimpleSegment::Request::BASE_URL', 'not a url'
        end

        it do
          expect do
            itly.group user_id: 'user_123', group_id: 'groupABC', properties: { active: 'yes' }
          end.to raise_error(Itly::RemoteError,
            'The client returned an error. Exception URI::InvalidURIError: bad URI(is not URI?): "not a url".')
        end
      end

      context 'production' do
        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
            options.environment = Itly::Options::Environment::PRODUCTION
          end

          expect(plugin.client).to receive(:group)
            .with(user_id: 'user_123', group_id: 'groupABC', traits: { active: 'yes' })
            .and_call_original

          stub_const 'SimpleSegment::Request::BASE_URL', 'not a url'

          itly.group user_id: 'user_123', group_id: 'groupABC', properties: { active: 'yes' }
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'plugin_segment: load()'],
            ['info', 'group(user_id: user_123, group_id: groupABC, properties: {:active=>"yes"})'],
            ['info', 'validate(event: #<Itly::Event: name: group, properties: {:active=>"yes"}>)'],
            ['info', 'plugin_segment: group(user_id: user_123, group_id: groupABC, '\
                    'properties: #<Itly::Event: name: group, properties: {:active=>"yes"}>)'],
            ['error', 'Itly Error in Itly::PluginSegment. Itly::RemoteError: The client returned an error. Exception '\
                      'URI::InvalidURIError: bad URI(is not URI?): "not a url".']
          ]
        end
      end
    end
  end

  describe '#track' do
    let(:logs) { StringIO.new }
    let(:plugin) { Itly::PluginSegment.new write_key: 'key123' }
    let(:itly) { Itly.new }
    let(:event) { Itly::Event.new name: 'custom_event', properties: { view: 'video' } }

    context 'success' do
      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
        end

        expect(plugin.client).to receive(:track)
          .with(user_id: 'user_123', event: 'custom_event', properties: { view: 'video' })

        itly.track user_id: 'user_123', event: event
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['warn', 'Environment not specified. Automatically set to development'],
          ['info', 'plugin_segment: load()'],
          ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
          ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
          ['info', 'plugin_segment: track(user_id: user_123, event: custom_event, properties: {:view=>"video"})']
        ]
      end
    end

    context 'failure' do
      context 'development' do
        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
            options.environment = Itly::Options::Environment::DEVELOPMENT
          end

          expect(plugin.client).to receive(:track)
            .with(user_id: 'user_123', event: 'custom_event', properties: { view: 'video' })
            .and_call_original

          stub_const 'SimpleSegment::Request::BASE_URL', 'not a url'
        end

        it do
          expect do
            itly.track user_id: 'user_123', event: event
          end.to raise_error(Itly::RemoteError, 'The client returned an error. Exception '\
            'URI::InvalidURIError: bad URI(is not URI?): "not a url".')
        end
      end

      context 'production' do
        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
            options.environment = Itly::Options::Environment::PRODUCTION
          end

          expect(plugin.client).to receive(:track)
            .with(user_id: 'user_123', event: 'custom_event', properties: { view: 'video' })
            .and_call_original

          stub_const 'SimpleSegment::Request::BASE_URL', 'not a url'

          itly.track user_id: 'user_123', event: event
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'plugin_segment: load()'],
            ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
            ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
            ['info', 'plugin_segment: track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
            ['error', 'Itly Error in Itly::PluginSegment. Itly::RemoteError: The client returned an error. Exception '\
                      'URI::InvalidURIError: bad URI(is not URI?): "not a url".']
          ]
        end
      end
    end
  end

  describe '#alias' do
    let(:logs) { StringIO.new }
    let(:plugin) { Itly::PluginSegment.new write_key: 'key123' }
    let(:itly) { Itly.new }

    context 'success' do
      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
        end

        expect(plugin.client).to receive(:alias)
          .with(user_id: 'user_123', previous_id: 'old_user')

        itly.alias user_id: 'user_123', previous_id: 'old_user'
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['warn', 'Environment not specified. Automatically set to development'],
          ['info', 'plugin_segment: load()'],
          ['info', 'alias(user_id: user_123, previous_id: old_user)'],
          ['info', 'plugin_segment: alias(user_id: user_123, previous_id: old_user)']
        ]
      end
    end

    context 'failure' do
      context 'development' do
        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
            options.environment = Itly::Options::Environment::DEVELOPMENT
          end

          expect(plugin.client).to receive(:alias)
            .with(user_id: 'user_123', previous_id: 'old_user')
            .and_call_original

          stub_const 'SimpleSegment::Request::BASE_URL', 'not a url'
        end

        it do
          expect do
            itly.alias user_id: 'user_123', previous_id: 'old_user'
          end.to raise_error(Itly::RemoteError, 'The client returned an error. Exception '\
            'URI::InvalidURIError: bad URI(is not URI?): "not a url".')
        end
      end

      context 'production' do
        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
            options.environment = Itly::Options::Environment::PRODUCTION
          end

          expect(plugin.client).to receive(:alias)
            .with(user_id: 'user_123', previous_id: 'old_user')
            .and_call_original

          stub_const 'SimpleSegment::Request::BASE_URL', 'not a url'

          itly.alias user_id: 'user_123', previous_id: 'old_user'
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'plugin_segment: load()'],
            ['info', 'alias(user_id: user_123, previous_id: old_user)'],
            ['info', 'plugin_segment: alias(user_id: user_123, previous_id: old_user)'],
            ['error', 'Itly Error in Itly::PluginSegment. Itly::RemoteError: The client returned an error. Exception '\
                      'URI::InvalidURIError: bad URI(is not URI?): "not a url".']
          ]
        end
      end
    end
  end
end
