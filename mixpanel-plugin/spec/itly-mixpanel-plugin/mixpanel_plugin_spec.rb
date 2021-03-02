# frozen_string_literal: true

describe Itly::MixpanelPlugin do
  include RspecLoggerHelpers

  it 'register itself' do
    expect(Itly.registered_plugins).to eq([Itly::MixpanelPlugin])
  end

  describe 'instance attributes' do
    it 'can read' do
      expect(Itly::MixpanelPlugin.new.respond_to?(:logger)).to be(true)
      expect(Itly::MixpanelPlugin.new.respond_to?(:client)).to be(true)
    end

    it 'cannot write' do
      expect(Itly::MixpanelPlugin.new.respond_to?(:logger=)).to be(false)
      expect(Itly::MixpanelPlugin.new.respond_to?(:client=)).to be(false)
    end
  end

  describe '#load' do
    let(:fake_logger) { double 'logger', info: nil }
    let(:itly) { Itly.new }

    before do
      itly.load do |options|
        options.plugins.mixpanel_plugin = { project_token: 'key123' }
        options.logger = fake_logger
      end
    end

    let(:mixpanel_plugin) { itly.instance_variable_get('@plugins_instances').first }

    it do
      expect(mixpanel_plugin.client.instance_variable_get('@token')).to eq('key123')
      expect(mixpanel_plugin.logger).to eq(fake_logger)
    end
  end

  describe '#identify' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }
    let(:mixpanel_client) { itly.instance_variable_get('@plugins_instances').first.client }

    before do
      itly.load { |o| o.logger = ::Logger.new logs }
    end

    context 'success' do
      before do
        expect(mixpanel_client.people).to receive(:set)
          .with('user_123', version: '4', some: 'data')

        itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['info', 'mixpanel_plugin: load()'],
          ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})'],
          ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
          ['info', 'mixpanel_plugin: identify(user_id: user_123, properties: #<Itly::Event: name: identify, '\
                   'properties: {:version=>"4", :some=>"data"}>)']
        ]
      end
    end

    context 'failure' do
      before do
        expect(mixpanel_client.people).to receive(:set)
          .with('user_123', version: '4', some: 'data')
          .and_call_original

        expect(Base64).to receive(:encode64).and_raise('Internal error')

        itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['info', 'mixpanel_plugin: load()'],
          ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})'],
          ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
          ['info', 'mixpanel_plugin: identify(user_id: user_123, properties: #<Itly::Event: name: identify, '\
                   'properties: {:version=>"4", :some=>"data"}>)'],
          ['error', 'Itly Error in Itly::MixpanelPlugin. RuntimeError: Internal error']
        ]
      end
    end
  end

  describe '#track' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }
    let(:mixpanel_client) { itly.instance_variable_get('@plugins_instances').first.client }
    let(:event) { Itly::Event.new name: 'custom_event', properties: { view: 'video' } }

    before do
      itly.load { |o| o.logger = ::Logger.new logs }
    end

    context 'success' do
      before do
        expect(mixpanel_client).to receive(:track)
          .with('user_123', 'custom_event', view: 'video')

        itly.track user_id: 'user_123', event: event
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['info', 'mixpanel_plugin: load()'],
          ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
          ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
          ['info', 'mixpanel_plugin: track(user_id: user_123, event: custom_event, properties: {:view=>"video"})']
        ]
      end
    end

    context 'failure' do
      before do
        expect(mixpanel_client).to receive(:track)
          .with('user_123', 'custom_event', view: 'video')
          .and_call_original

        expect(Base64).to receive(:encode64).and_raise('Internal error')

        itly.track user_id: 'user_123', event: event
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['info', 'mixpanel_plugin: load()'],
          ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
          ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
          ['info', 'mixpanel_plugin: track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
          ['error', 'Itly Error in Itly::MixpanelPlugin. RuntimeError: Internal error']
        ]
      end
    end
  end

  describe '#alias' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }
    let(:mixpanel_client) { itly.instance_variable_get('@plugins_instances').first.client }

    before do
      itly.load { |o| o.logger = ::Logger.new logs }
    end

    context 'success' do
      before do
        expect(mixpanel_client).to receive(:alias)
          .with('user_123', 'old_user')

        itly.alias user_id: 'user_123', previous_id: 'old_user'
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['info', 'mixpanel_plugin: load()'],
          ['info', 'alias(user_id: user_123, previous_id: old_user)'],
          ['info', 'mixpanel_plugin: alias(user_id: user_123, previous_id: old_user)']
        ]
      end
    end

    context 'failure' do
      before do
        expect(mixpanel_client).to receive(:alias)
          .with('user_123', 'old_user')
          .and_call_original

        expect(Base64).to receive(:encode64).and_raise('Internal error')

        itly.alias user_id: 'user_123', previous_id: 'old_user'
      end

      it do
        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['info', 'mixpanel_plugin: load()'],
          ['info', 'alias(user_id: user_123, previous_id: old_user)'],
          ['info', 'mixpanel_plugin: alias(user_id: user_123, previous_id: old_user)'],
          ['error', 'Itly Error in Itly::MixpanelPlugin. RuntimeError: Internal error']
        ]
      end
    end
  end
end
