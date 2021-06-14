# frozen_string_literal: true

describe Itly::Plugin::Testing do
  include RspecLoggerHelpers

  describe 'instance attributes' do
    let(:plugin) { Itly::Plugin::Testing.new }

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
      let!(:plugin) { Itly::Plugin::Testing.new }

      it do
        expect(plugin.instance_variable_get('@calls')).to be_a(Concurrent::Hash)
        expect(plugin.disabled).to be(false)
      end
    end

    describe 'with values' do
      let!(:plugin) { Itly::Plugin::Testing.new disabled: true }

      it do
        expect(plugin.instance_variable_get('@calls')).to be_a(Concurrent::Hash)
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
      let(:plugin) { Itly::Plugin::Testing.new }

      it do
        expect(plugin.logger).to eq(logger)
      end
    end

    describe 'logging' do
      context 'enabled' do
        let(:plugin) { Itly::Plugin::Testing.new }

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'testing: load()']
          ]
        end
      end

      context 'disabled' do
        let(:plugin) { Itly::Plugin::Testing.new disabled: true }

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'testing: load()'],
            ['info', 'testing: plugin is disabled!']
          ]
        end
      end
    end
  end

  describe 'get methods' do
    let(:itly) { Itly.new }
    let(:plugin) { Itly::Plugin::Testing.new }

    let(:event1) { TestEvent1.new name: 'test_event' }
    let(:event2) { TestEvent1.new name: 'test_event' }
    let(:event3) { TestEvent2.new name: 'test_event' }
    let(:event4) { TestEvent1.new name: 'test_event' }

    before do
      itly.load { |o| o.plugins = [plugin] }

      itly.alias user_id: 'user_123', previous_id: 'old_456'
      itly.track user_id: 'user_123', event: event1
      itly.track user_id: 'user_123', event: event2
      itly.track user_id: 'user_123', event: event3
      itly.track user_id: 'other_user', event: event4
    end

    describe '#all' do
      it 'without user_id filtering' do
        expect(plugin.all).to eq([event1, event2, event3, event4])
      end

      it 'filtering by user_id' do
        expect(plugin.all(user_id: 'user_123')).to eq([event1, event2, event3])
        expect(plugin.all(user_id: 'other_user')).to eq([event4])
      end
    end

    describe '#of_type' do
      it 'without user_id filtering' do
        expect(plugin.of_type(class_name: TestEvent1)).to eq([event1, event2, event4])
        expect(plugin.of_type(class_name: TestEvent2)).to eq([event3])
      end

      it 'filtering by user_id' do
        expect(plugin.of_type(class_name: TestEvent1, user_id: 'user_123')).to eq([event1, event2])
        expect(plugin.of_type(class_name: TestEvent2, user_id: 'user_123')).to eq([event3])
        expect(plugin.of_type(class_name: TestEvent1, user_id: 'other_user')).to eq([event4])
        expect(plugin.of_type(class_name: TestEvent2, user_id: 'other_user')).to eq([])
      end
    end

    describe '#first_of_type' do
      it 'without user_id filtering' do
        expect(plugin.first_of_type(class_name: TestEvent1)).to eq(event1)
        expect(plugin.first_of_type(class_name: TestEvent2)).to eq(event3)
      end

      it 'filtering by user_id' do
        expect(plugin.first_of_type(class_name: TestEvent1, user_id: 'user_123')).to eq(event1)
        expect(plugin.first_of_type(class_name: TestEvent2, user_id: 'user_123')).to eq(event3)
        expect(plugin.first_of_type(class_name: TestEvent1, user_id: 'other_user')).to eq(event4)
        expect(plugin.first_of_type(class_name: TestEvent2, user_id: 'other_user')).to be(nil)
      end
    end
  end

  describe '#alias' do
    let(:itly) { Itly.new }
    let(:plugin) { Itly::Plugin::Testing.new }
    let(:options) { Itly::Plugin::Testing::AliasOptions.new }

    before do
      itly.load { |o| o.plugins = [plugin] }
      itly.alias user_id: 'user_123', previous_id: 'old_456', options: { 'testing' => options }
    end

    let(:calls) { plugin.instance_variable_get '@calls' }

    it do
      expect(calls.keys).to eq(%w[alias])
      expect(calls['alias']).to eq(
        [
          { user_id: 'user_123', previous_id: 'old_456', options: options }
        ]
      )
    end
  end

  describe '#identify' do
    let(:itly) { Itly.new }
    let(:plugin) { Itly::Plugin::Testing.new }
    let(:options) { Itly::Plugin::Testing::IdentifyOptions.new }

    before do
      itly.load { |o| o.plugins = [plugin] }
      itly.identify user_id: 'user_123', properties: { data: 'from props' }, options: { 'testing' => options }
    end

    let(:calls) { plugin.instance_variable_get '@calls' }

    it do
      expect(calls.keys).to eq(%w[identify])
      expect(calls['identify']).to eq(
        [
          { user_id: 'user_123', properties: { data: 'from props' }, options: options }
        ]
      )
    end
  end

  describe '#group' do
    let(:itly) { Itly.new }
    let(:plugin) { Itly::Plugin::Testing.new }
    let(:options) { Itly::Plugin::Testing::GroupOptions.new }

    before do
      itly.load { |o| o.plugins = [plugin] }
      itly.group(
        user_id: 'user_123', group_id: 'grp_id', properties: { data: 'from props' }, options: { 'testing' => options }
      )
    end

    let(:calls) { plugin.instance_variable_get '@calls' }

    it do
      expect(calls.keys).to eq(%w[group])
      expect(calls['group']).to eq(
        [
          { user_id: 'user_123', group_id: 'grp_id', properties: { data: 'from props' }, options: options }
        ]
      )
    end
  end

  describe '#track' do
    let(:itly) { Itly.new }
    let(:plugin) { Itly::Plugin::Testing.new }
    let(:options) { Itly::Plugin::Testing::TrackOptions.new }
    let(:event) { Itly::Event.new name: 'test_event' }

    before do
      itly.load { |o| o.plugins = [plugin] }
      itly.track user_id: 'user_123', event: event, options: { 'testing' => options }
    end

    let(:calls) { plugin.instance_variable_get '@calls' }

    it do
      expect(calls.keys).to eq(%w[track])
      expect(calls['track']).to eq(
        [
          { user_id: 'user_123', event: event, options: options }
        ]
      )
    end
  end

  describe '#enabled?' do
    describe 'enabled' do
      let(:plugin) { Itly::Plugin::Testing.new }

      it do
        expect(plugin.send(:enabled?)).to be(true)
      end
    end

    describe 'disabled' do
      let(:plugin) { Itly::Plugin::Testing.new disabled: true }

      it do
        expect(plugin.send(:enabled?)).to be(false)
      end
    end
  end
end
