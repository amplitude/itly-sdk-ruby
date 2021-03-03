# frozen_string_literal: true

describe Itly::PluginMixpanel do
  include RspecLoggerHelpers

  it 'register itself' do
    expect(Itly.registered_plugins).to eq([Itly::PluginMixpanel])
  end

  describe 'instance attributes' do
    it 'can read' do
      expect(Itly::PluginMixpanel.new.respond_to?(:logger)).to be(true)
      expect(Itly::PluginMixpanel.new.respond_to?(:client)).to be(true)
    end

    it 'cannot write' do
      expect(Itly::PluginMixpanel.new.respond_to?(:logger=)).to be(false)
      expect(Itly::PluginMixpanel.new.respond_to?(:client=)).to be(false)
    end
  end

  describe '#load' do
    let(:fake_logger) { double 'logger', info: nil }
    let(:itly) { Itly.new }

    before do
      itly.load do |options|
        options.plugins.mixpanel = { project_token: 'key123' }
        options.logger = fake_logger
      end
    end

    let(:plugin_mixpanel) { itly.instance_variable_get('@plugins_instances').first }

    it do
      expect(plugin_mixpanel.client.instance_variable_get('@token')).to eq('key123')
      expect(plugin_mixpanel.logger).to eq(fake_logger)
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
          ['info', 'plugin_mixpanel: load()'],
          ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})'],
          ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
          ['info', 'plugin_mixpanel: identify(user_id: user_123, properties: #<Itly::Event: name: identify, '\
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
          ['info', 'plugin_mixpanel: load()'],
          ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})'],
          ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
          ['info', 'plugin_mixpanel: identify(user_id: user_123, properties: #<Itly::Event: name: identify, '\
                   'properties: {:version=>"4", :some=>"data"}>)'],
          ['error', 'Itly Error in Itly::PluginMixpanel. RuntimeError: Internal error']
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
          ['info', 'plugin_mixpanel: load()'],
          ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
          ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
          ['info', 'plugin_mixpanel: track(user_id: user_123, event: custom_event, properties: {:view=>"video"})']
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
          ['info', 'plugin_mixpanel: load()'],
          ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
          ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
          ['info', 'plugin_mixpanel: track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
          ['error', 'Itly Error in Itly::PluginMixpanel. RuntimeError: Internal error']
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
          ['info', 'plugin_mixpanel: load()'],
          ['info', 'alias(user_id: user_123, previous_id: old_user)'],
          ['info', 'plugin_mixpanel: alias(user_id: user_123, previous_id: old_user)']
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
          ['info', 'plugin_mixpanel: load()'],
          ['info', 'alias(user_id: user_123, previous_id: old_user)'],
          ['info', 'plugin_mixpanel: alias(user_id: user_123, previous_id: old_user)'],
          ['error', 'Itly Error in Itly::PluginMixpanel. RuntimeError: Internal error']
        ]
      end
    end
  end
end
