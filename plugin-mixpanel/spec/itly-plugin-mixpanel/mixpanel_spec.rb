# frozen_string_literal: true

describe Itly::Plugin::Mixpanel do
  include RspecLoggerHelpers

  describe 'instance attributes' do
    let(:plugin) { Itly::Plugin::Mixpanel.new project_token: 'abc123' }

    it 'can read' do
      expect(plugin.respond_to?(:client)).to be(true)
      expect(plugin.respond_to?(:disabled)).to be(true)
    end

    it 'cannot write' do
      expect(plugin.respond_to?(:client=)).to be(false)
      expect(plugin.respond_to?(:disabled=)).to be(false)
    end
  end

  describe '#initialize' do
    describe 'default values' do
      let!(:plugin) { Itly::Plugin::Mixpanel.new project_token: 'key123' }

      it do
        expect(plugin.instance_variable_get('@project_token')).to eq('key123')
        expect(plugin.disabled).to be(false)
      end
    end

    describe 'with values' do
      let!(:plugin) { Itly::Plugin::Mixpanel.new project_token: 'key123', disabled: true }

      it do
        expect(plugin.instance_variable_get('@project_token')).to eq('key123')
        expect(plugin.disabled).to be(true)
      end
    end
  end

  describe '#load' do
    let(:logs) { StringIO.new }
    let(:logger) { Logger.new logs }
    let(:itly) { Itly.new }

    context 'single plugin' do
      let(:plugin) { Itly::Plugin::Mixpanel.new project_token: 'key123' }

      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = logger
        end
      end

      it do
        expect(plugin.client).to be_a_kind_of(::Mixpanel::Tracker)
        expect(plugin.client.instance_variable_get('@token')).to eq('key123')
        expect(plugin.instance_variable_get('@logger')).to eq(logger)
      end
    end

    context 'multiple plugins' do
      let(:plugin1) { Itly::Plugin::Mixpanel.new project_token: 'key123' }
      let(:plugin2) { Itly::Plugin::Mixpanel.new project_token: 'key456' }

      before do
        itly.load do |options|
          options.plugins = [plugin1, plugin2]
          options.logger = logger
        end
      end

      it do
        expect(plugin1.client).to be_a_kind_of(::Mixpanel::Tracker)
        expect(plugin2.client).to be_a_kind_of(::Mixpanel::Tracker)
        expect(plugin1.client).not_to eq(plugin2.client)

        expect(plugin1.client.instance_variable_get('@token')).to eq('key123')
        expect(plugin2.client.instance_variable_get('@token')).to eq('key456')

        expect(plugin1.instance_variable_get('@logger')).to eq(logger)
        expect(plugin2.instance_variable_get('@logger')).to eq(logger)
      end
    end

    context 'disabled' do
      let(:plugin) { Itly::Plugin::Mixpanel.new project_token: 'key123', disabled: true }

      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = logger
        end
      end

      it do
        expect(plugin.client).to be(nil)
        expect(plugin.instance_variable_get('@logger')).to eq(logger)
      end
    end

    describe 'logging' do
      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = logger
        end
      end

      context 'enabled' do
        let(:plugin) { Itly::Plugin::Mixpanel.new project_token: 'key123' }

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'mixpanel: load()']
          ]
        end
      end

      context 'disabled' do
        let(:plugin) { Itly::Plugin::Mixpanel.new project_token: 'key123', disabled: true }

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'mixpanel: load()'],
            ['info', 'mixpanel: plugin is disabled!']
          ]
        end
      end
    end
  end

  describe '#identify' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }

    describe 'enabled' do
      let(:plugin) { Itly::Plugin::Mixpanel.new project_token: 'abc123' }

      context 'success' do
        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
          end

          expect(plugin.client.people).to receive(:set)
            .with('user_123', version: '4', some: 'data')

          itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'mixpanel: load()'],
            ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})'],
            ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
            ['info', 'mixpanel: identify(user_id: user_123, properties: {:version=>"4", :some=>"data"}, '\
                     'options: )']
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

            expect(plugin.client.people).to receive(:set)
              .with('user_123', version: '4', some: 'data')
              .and_call_original

            expect(Base64).to receive(:encode64).and_raise('Internal error')
          end

          it do
            expect do
              itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
            end.to raise_error(RuntimeError, 'Internal error')
          end
        end

        context 'production' do
          before do
            itly.load do |options|
              options.plugins = [plugin]
              options.logger = ::Logger.new logs
              options.environment = Itly::Options::Environment::PRODUCTION
            end

            expect(plugin.client.people).to receive(:set)
              .with('user_123', version: '4', some: 'data')
              .and_call_original

            expect(Base64).to receive(:encode64).and_raise('Internal error')

            itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'mixpanel: load()'],
              ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})'],
              ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
              ['info', 'mixpanel: identify(user_id: user_123, properties: {:version=>"4", :some=>"data"}, '\
                       'options: )'],
              ['error', 'Itly Error in Itly::Plugin::Mixpanel. RuntimeError: Internal error']
            ]
          end
        end
      end
    end

    context 'disabled' do
      let(:plugin) { Itly::Plugin::Mixpanel.new project_token: 'abc123', disabled: true }

      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
        end
      end

      it do
        expect do
          itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
        end.not_to raise_error
      end
    end
  end

  describe '#track' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }
    let(:event) { Itly::Event.new name: 'custom_event', properties: { view: 'video' } }

    describe 'enabled' do
      let(:plugin) { Itly::Plugin::Mixpanel.new project_token: 'abc123' }

      context 'success' do
        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
          end

          expect(plugin.client).to receive(:track)
            .with('user_123', 'custom_event', view: 'video')

          itly.track user_id: 'user_123', event: event
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'mixpanel: load()'],
            ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
            ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
            ['info', 'mixpanel: track(user_id: user_123, event: custom_event, properties: {:view=>"video"}, '\
                     'options: )']
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
              .with('user_123', 'custom_event', view: 'video')
              .and_call_original

            expect(Base64).to receive(:encode64).and_raise('Internal error')
          end

          it do
            expect do
              itly.track user_id: 'user_123', event: event
            end.to raise_error(RuntimeError, 'Internal error')
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
              .with('user_123', 'custom_event', view: 'video')
              .and_call_original

            expect(Base64).to receive(:encode64).and_raise('Internal error')

            itly.track user_id: 'user_123', event: event
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'mixpanel: load()'],
              ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
              ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
              ['info', 'mixpanel: track(user_id: user_123, event: custom_event, properties: {:view=>"video"}, '\
                       'options: )'],
              ['error', 'Itly Error in Itly::Plugin::Mixpanel. RuntimeError: Internal error']
            ]
          end
        end
      end
    end

    context 'disabled' do
      let(:plugin) { Itly::Plugin::Mixpanel.new project_token: 'abc123', disabled: true }

      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
        end
      end

      it do
        expect do
          itly.track user_id: 'user_123', event: event
        end.not_to raise_error
      end
    end
  end

  describe '#alias' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }

    describe 'enabled' do
      let(:plugin) { Itly::Plugin::Mixpanel.new project_token: 'abc123' }

      context 'success' do
        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = ::Logger.new logs
          end

          expect(plugin.client).to receive(:alias)
            .with('user_123', 'old_user')

          itly.alias user_id: 'user_123', previous_id: 'old_user'
        end

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'mixpanel: load()'],
            ['info', 'alias(user_id: user_123, previous_id: old_user)'],
            ['info', 'mixpanel: alias(user_id: user_123, previous_id: old_user, options: )']
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
              .with('user_123', 'old_user')
              .and_call_original

            expect(Base64).to receive(:encode64).and_raise('Internal error')
          end

          it do
            expect do
              itly.alias user_id: 'user_123', previous_id: 'old_user'
            end.to raise_error(RuntimeError, 'Internal error')
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
              .with('user_123', 'old_user')
              .and_call_original

            expect(Base64).to receive(:encode64).and_raise('Internal error')

            itly.alias user_id: 'user_123', previous_id: 'old_user'
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'mixpanel: load()'],
              ['info', 'alias(user_id: user_123, previous_id: old_user)'],
              ['info', 'mixpanel: alias(user_id: user_123, previous_id: old_user, options: )'],
              ['error', 'Itly Error in Itly::Plugin::Mixpanel. RuntimeError: Internal error']
            ]
          end
        end
      end
    end

    context 'disabled' do
      let(:plugin) { Itly::Plugin::Mixpanel.new project_token: 'abc123', disabled: true }

      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
        end
      end

      it do
        expect do
          itly.alias user_id: 'user_123', previous_id: 'old_user'
        end.not_to raise_error
      end
    end
  end

  describe '#enabled?' do
    describe 'enabled' do
      let(:plugin) { Itly::Plugin::Mixpanel.new project_token: 'abc123' }

      it do
        expect(plugin.send(:enabled?)).to be(true)
      end
    end

    describe 'disabled' do
      let(:plugin) { Itly::Plugin::Mixpanel.new project_token: 'abc123', disabled: true }

      it do
        expect(plugin.send(:enabled?)).to be(false)
      end
    end
  end
end
