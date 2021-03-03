# frozen_string_literal: true

describe Itly::PluginSegment do
  include RspecLoggerHelpers

  it 'register itself' do
    expect(Itly.registered_plugins).to eq([Itly::PluginSegment])
  end

  describe 'instance attributes' do
    it 'can read' do
      expect(Itly::PluginSegment.new.respond_to?(:logger)).to be(true)
      expect(Itly::PluginSegment.new.respond_to?(:client)).to be(true)
    end

    it 'cannot write' do
      expect(Itly::PluginSegment.new.respond_to?(:logger=)).to be(false)
      expect(Itly::PluginSegment.new.respond_to?(:client=)).to be(false)
    end
  end

  describe '#load' do
    let(:fake_logger) { double 'logger', info: nil }
    let(:itly) { Itly.new }

    before do
      itly.load do |options|
        options.plugins.plugin_segment = { write_key: 'key123' }
        options.logger = fake_logger
      end
    end

    let(:plugin_segment) { itly.instance_variable_get('@plugins_instances').first }

    it do
      expect(plugin_segment.client.config.write_key).to eq('key123')
      expect(plugin_segment.logger).to eq(fake_logger)
    end
  end

  describe '#identify' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }
    let(:segment_client) { itly.instance_variable_get('@plugins_instances').first.client }

    before do
      itly.load do |options|
        options.plugins.plugin_segment = { write_key: 'key123' }
        options.logger = ::Logger.new logs
      end
    end

    context 'success' do
      before do
        expect(segment_client).to receive(:identify)
          .with(user_id: 'user_123', traits: { version: '4', some: 'data' })

        itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['info', 'plugin_segment: load()'],
          ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})'],
          ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
          ['info', 'plugin_segment: identify(user_id: user_123, properties: #<Itly::Event: name: identify, '\
                   'properties: {:version=>"4", :some=>"data"}>)']
        ]
      end
    end

    context 'failure' do
      before do
        expect(segment_client).to receive(:identify)
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

  describe '#group' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }
    let(:segment_client) { itly.instance_variable_get('@plugins_instances').first.client }

    before do
      itly.load do |options|
        options.plugins.plugin_segment = { write_key: 'key123' }
        options.logger = ::Logger.new logs
      end
    end

    context 'success' do
      before do
        expect(segment_client).to receive(:group)
          .with(user_id: 'user_123', group_id: 'groupABC', traits: { active: 'yes' })

        itly.group user_id: 'user_123', group_id: 'groupABC', properties: { active: 'yes' }
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['info', 'plugin_segment: load()'],
          ['info', 'group(user_id: user_123, group_id: groupABC, properties: {:active=>"yes"})'],
          ['info', 'validate(event: #<Itly::Event: name: group, properties: {:active=>"yes"}>)'],
          ['info', 'plugin_segment: group(user_id: user_123, group_id: groupABC, '\
                   'properties: #<Itly::Event: name: group, properties: {:active=>"yes"}>)']
        ]
      end
    end

    context 'failure' do
      before do
        expect(segment_client).to receive(:group)
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

  describe '#track' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }
    let(:event) { Itly::Event.new name: 'custom_event', properties: { view: 'video' } }
    let(:segment_client) { itly.instance_variable_get('@plugins_instances').first.client }

    before do
      itly.load do |options|
        options.plugins.plugin_segment = { write_key: 'key123' }
        options.logger = ::Logger.new logs
      end
    end

    context 'success' do
      before do
        expect(segment_client).to receive(:track)
          .with(user_id: 'user_123', event: 'custom_event', properties: { view: 'video' })

        itly.track user_id: 'user_123', event: event
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['info', 'plugin_segment: load()'],
          ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
          ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
          ['info', 'plugin_segment: track(user_id: user_123, event: custom_event, properties: {:view=>"video"})']
        ]
      end
    end

    context 'failure' do
      before do
        expect(segment_client).to receive(:track)
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

  describe '#alias' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }
    let(:segment_client) { itly.instance_variable_get('@plugins_instances').first.client }

    before do
      itly.load do |options|
        options.plugins.plugin_segment = { write_key: 'key123' }
        options.logger = ::Logger.new logs
      end
    end

    context 'success' do
      before do
        expect(segment_client).to receive(:alias)
          .with(user_id: 'user_123', previous_id: 'old_user')

        itly.alias user_id: 'user_123', previous_id: 'old_user'
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['info', 'plugin_segment: load()'],
          ['info', 'alias(user_id: user_123, previous_id: old_user)'],
          ['info', 'plugin_segment: alias(user_id: user_123, previous_id: old_user)']
        ]
      end
    end

    context 'failure' do
      before do
        expect(segment_client).to receive(:alias)
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
