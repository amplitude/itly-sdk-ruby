# frozen_string_literal: true

describe Itly::Plugin::Segment do
  include RspecLoggerHelpers

  describe 'instance attributes' do
    let(:plugin) { Itly::Plugin::Segment.new write_key: 'abc123' }

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
      let!(:plugin) { Itly::Plugin::Segment.new write_key: 'key123' }

      it do
        expect(plugin.instance_variable_get('@write_key')).to eq('key123')
        expect(plugin.disabled).to be(false)
      end
    end

    describe 'with values' do
      let!(:plugin) { Itly::Plugin::Segment.new write_key: 'key123', disabled: true }

      it do
        expect(plugin.instance_variable_get('@write_key')).to eq('key123')
        expect(plugin.disabled).to be(true)
      end
    end
  end

  describe '#load' do
    let(:logs) { StringIO.new }
    let(:logger) { Logger.new logs }
    let(:itly) { Itly.new }

    context 'single plugin' do
      let(:plugin) { Itly::Plugin::Segment.new write_key: 'key123' }

      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = logger
        end
      end

      it do
        expect(plugin.client).to be_a_kind_of(::SimpleSegment::Client)
        expect(plugin.client.config.write_key).to eq('key123')
        expect(plugin.instance_variable_get('@logger')).to eq(logger)
      end
    end

    context 'multiple plugins' do
      let(:plugin1) { Itly::Plugin::Segment.new write_key: 'key123' }
      let(:plugin2) { Itly::Plugin::Segment.new write_key: 'key456' }

      before do
        itly.load do |options|
          options.plugins = [plugin1, plugin2]
          options.logger = logger
        end
      end

      it do
        expect(plugin1.client).to be_a_kind_of(::SimpleSegment::Client)
        expect(plugin2.client).to be_a_kind_of(::SimpleSegment::Client)
        expect(plugin1.client).not_to eq(plugin2.client)

        expect(plugin1.client.config.write_key).to eq('key123')
        expect(plugin2.client.config.write_key).to eq('key456')

        expect(plugin1.instance_variable_get('@logger')).to eq(logger)
        expect(plugin2.instance_variable_get('@logger')).to eq(logger)
      end
    end

    context 'disabled' do
      let(:plugin) { Itly::Plugin::Segment.new write_key: 'key123', disabled: true }

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
        let(:plugin) { Itly::Plugin::Segment.new write_key: 'key123' }

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'segment: load()']
          ]
        end
      end

      context 'disabled' do
        let(:plugin) { Itly::Plugin::Segment.new write_key: 'key123', disabled: true }

        it do
          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'segment: load()'],
            ['info', 'segment: plugin is disabled!']
          ]
        end
      end
    end
  end

  describe '#identify' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }

    describe 'enabled' do
      let(:plugin) { Itly::Plugin::Segment.new write_key: 'key123' }
      let(:logger) { ::Logger.new logs }

      context 'success' do
        let(:response) { double 'response', code: '201', body: 'raw data' }

        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = logger
          end
        end

        context 'default' do
          before do
            expect(plugin.client).to receive(:identify)
              .with(user_id: 'user_123', traits: { version: '4', some: 'data' })
              .and_return(response)

            itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'segment: load()'],
              ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})'],
              ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
              ['info', 'segment: identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})']
            ]
          end
        end

        context 'with callback' do
          before do
            expect(plugin.client).to receive(:identify)
              .with(user_id: 'user_123', traits: { version: '4', some: 'data' })
              .and_return(response)

            itly.identify(
              user_id: 'user_123', properties: { version: '4', some: 'data' },
              options: { 'segment' => Itly::Plugin::Segment::IdentifyOptions.new(
                callback: ->(code, body) { logger.info "from-callback: code: #{code} body: #{body}" }
              ) }
            )
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'segment: load()'],
              ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"}, '\
                       'options: {"segment"=>#<Segment::IdentifyOptions callback: provided>})'],
              ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
              ['info', 'segment: identify(user_id: user_123, properties: {:version=>"4", :some=>"data"}, '\
                       'options: #<Segment::IdentifyOptions callback: provided>)'],
              ['info', 'from-callback: code: 201 body: raw data']
            ]
          end
        end

        context 'with options' do
          before do
            expect(plugin.client).to receive(:identify).with(
              user_id: 'user_123', traits: { version: '4', some: 'data' }, integrations: { 'content' => true },
              anonymous_id: 'anID'
            ).and_return(response)

            itly.identify(
              user_id: 'user_123', properties: { version: '4', some: 'data' },
              options: { 'segment' => Itly::Plugin::Segment::IdentifyOptions.new(
                integrations: { 'content' => true }, anonymous_id: 'anID'
              ) }
            )
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'segment: load()'],
              ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"}, options: '\
                       '{"segment"=>#<Segment::IdentifyOptions callback: nil '\
                       'integrations: {"content"=>true} anonymous_id: anID>})'],
              ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
              ['info', 'segment: identify(user_id: user_123, properties: {:version=>"4", :some=>"data"}, '\
                       'options: #<Segment::IdentifyOptions callback: nil '\
                       'integrations: {"content"=>true} anonymous_id: anID>)']
            ]
          end
        end
      end

      context 'failure' do
        context 'development' do
          before do
            itly.load do |options|
              options.plugins = [plugin]
              options.logger = logger
              options.environment = Itly::Options::Environment::DEVELOPMENT
            end

            expect(plugin.client).to receive(:identify)
              .with(user_id: 'user_123', traits: { version: '4', some: 'data' })
              .and_call_original

            stub_const 'SimpleSegment::Request::BASE_URL', 'not a url'
          end

          it do
            itly.identify user_id: 'user_123', properties: { version: '4', some: 'data' }
          end
        end

        context 'production' do
          before do
            itly.load do |options|
              options.plugins = [plugin]
              options.logger = logger
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
              ['info', 'segment: load()'],
              ['info', 'identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})'],
              ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:version=>"4", :some=>"data"}>)'],
              ['info', 'segment: identify(user_id: user_123, properties: {:version=>"4", :some=>"data"})']
            ]
          end
        end
      end
    end

    context 'disabled' do
      let(:plugin) { Itly::Plugin::Segment.new write_key: 'key123', disabled: true }

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

  describe '#group' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }

    describe 'enabled' do
      let(:plugin) { Itly::Plugin::Segment.new write_key: 'key123' }
      let(:logger) { ::Logger.new logs }

      context 'success' do
        let(:response) { double 'response', code: '201', body: 'raw data' }

        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = logger
          end
        end

        context 'default' do
          before do
            expect(plugin.client).to receive(:group)
              .with(user_id: 'user_123', group_id: 'groupABC', traits: { active: 'yes' })
              .and_return(response)

            itly.group user_id: 'user_123', group_id: 'groupABC', properties: { active: 'yes' }
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'segment: load()'],
              ['info', 'group(user_id: user_123, group_id: groupABC, properties: {:active=>"yes"})'],
              ['info', 'validate(event: #<Itly::Event: name: group, properties: {:active=>"yes"}>)'],
              ['info', 'segment: group(user_id: user_123, group_id: groupABC, properties: {:active=>"yes"})']
            ]
          end
        end

        context 'with callback' do
          before do
            expect(plugin.client).to receive(:group)
              .with(user_id: 'user_123', group_id: 'groupABC', traits: { active: 'yes' })
              .and_return(response)

            itly.group(
              user_id: 'user_123', group_id: 'groupABC', properties: { active: 'yes' },
              options: { 'segment' => Itly::Plugin::Segment::GroupOptions.new(
                callback: ->(code, body) { logger.info "from-callback: code: #{code} body: #{body}" }
              ) }
            )
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'segment: load()'],
              ['info', 'group(user_id: user_123, group_id: groupABC, properties: {:active=>"yes"}, '\
                       'options: {"segment"=>#<Segment::GroupOptions callback: provided>})'],
              ['info', 'validate(event: #<Itly::Event: name: group, properties: {:active=>"yes"}>)'],
              ['info', 'segment: group(user_id: user_123, group_id: groupABC, properties: {:active=>"yes"}, '\
                       'options: #<Segment::GroupOptions callback: provided>)'],
              ['info', 'from-callback: code: 201 body: raw data']
            ]
          end
        end

        context 'with options' do
          before do
            expect(plugin.client).to receive(:group).with(
              user_id: 'user_123', group_id: 'groupABC', traits: { active: 'yes' },
              integrations: { 'content' => true }, anonymous_id: 'anID'
            ).and_return(response)

            itly.group(
              user_id: 'user_123', group_id: 'groupABC', properties: { active: 'yes' },
              options: { 'segment' => Itly::Plugin::Segment::GroupOptions.new(
                integrations: { 'content' => true }, anonymous_id: 'anID'
              ) }
            )
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'segment: load()'],
              ['info', 'group(user_id: user_123, group_id: groupABC, properties: {:active=>"yes"}, '\
                       'options: {"segment"=>#<Segment::GroupOptions callback: nil '\
                       'integrations: {"content"=>true} anonymous_id: anID>})'],
              ['info', 'validate(event: #<Itly::Event: name: group, properties: {:active=>"yes"}>)'],
              ['info', 'segment: group(user_id: user_123, group_id: groupABC, properties: {:active=>"yes"}, '\
                       'options: #<Segment::GroupOptions callback: nil '\
                       'integrations: {"content"=>true} anonymous_id: anID>)']
            ]
          end
        end
      end

      context 'failure' do
        context 'development' do
          before do
            itly.load do |options|
              options.plugins = [plugin]
              options.logger = logger
              options.environment = Itly::Options::Environment::DEVELOPMENT
            end

            expect(plugin.client).to receive(:group)
              .with(user_id: 'user_123', group_id: 'groupABC', traits: { active: 'yes' })
              .and_call_original

            stub_const 'SimpleSegment::Request::BASE_URL', 'not a url'
          end

          it do
            itly.group user_id: 'user_123', group_id: 'groupABC', properties: { active: 'yes' }
          end
        end

        context 'production' do
          before do
            itly.load do |options|
              options.plugins = [plugin]
              options.logger = logger
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
              ['info', 'segment: load()'],
              ['info', 'group(user_id: user_123, group_id: groupABC, properties: {:active=>"yes"})'],
              ['info', 'validate(event: #<Itly::Event: name: group, properties: {:active=>"yes"}>)'],
              ['info', 'segment: group(user_id: user_123, group_id: groupABC, properties: {:active=>"yes"})']
            ]
          end
        end
      end
    end

    context 'disabled' do
      let(:plugin) { Itly::Plugin::Segment.new write_key: 'key123', disabled: true }

      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
        end
      end

      it do
        expect do
          itly.group user_id: 'user_123', group_id: 'groupABC', properties: { active: 'yes' }
        end.not_to raise_error
      end
    end
  end

  describe '#page' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }

    describe 'enabled' do
      let(:plugin) { Itly::Plugin::Segment.new write_key: 'key123' }
      let(:logger) { ::Logger.new logs }

      context 'success' do
        let(:response) { double 'response', code: '201', body: 'raw data' }

        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = logger
          end
        end

        context 'default' do
          before do
            expect(plugin.client).to receive(:page)
              .with(user_id: 'user_123', name: 'pageABC', properties: { active: 'yes', category: 'Prd' })
              .and_return(response)

            itly.page user_id: 'user_123', category: 'Prd', name: 'pageABC', properties: { active: 'yes' }
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'segment: load()'],
              ['info', 'page(user_id: user_123, category: Prd, name: pageABC, properties: {:active=>"yes"})'],
              ['info', 'validate(event: #<Itly::Event: name: page, properties: {:active=>"yes"}>)'],
              ['info', 'segment: page(user_id: user_123, category: Prd, name: pageABC, properties: {:active=>"yes"})']
            ]
          end
        end

        context 'with minimum args' do
          before do
            expect(plugin.client).to receive(:page)
              .with(user_id: 'user_123', properties: {})
              .and_return(response)

            itly.page user_id: 'user_123'
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'segment: load()'],
              ['info', 'page(user_id: user_123)'],
              ['info', 'validate(event: #<Itly::Event: name: page, properties: {}>)'],
              ['info', 'segment: page(user_id: user_123)']
            ]
          end
        end

        context 'with callback' do
          before do
            expect(plugin.client).to receive(:page)
              .with(user_id: 'user_123', name: 'pageABC', properties: { active: 'yes', category: 'Prd' })
              .and_return(response)

            itly.page(
              user_id: 'user_123', category: 'Prd', name: 'pageABC', properties: { active: 'yes' },
              options: { 'segment' => Itly::Plugin::Segment::PageOptions.new(
                callback: ->(code, body) { logger.info "from-callback: code: #{code} body: #{body}" }
              ) }
            )
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'segment: load()'],
              ['info', 'page(user_id: user_123, category: Prd, name: pageABC, properties: {:active=>"yes"}, '\
                       'options: {"segment"=>#<Segment::PageOptions callback: provided>})'],
              ['info', 'validate(event: #<Itly::Event: name: page, properties: {:active=>"yes"}>)'],
              ['info', 'segment: page(user_id: user_123, category: Prd, name: pageABC, properties: {:active=>"yes"}, '\
                       'options: #<Segment::PageOptions callback: provided>)'],
              ['info', 'from-callback: code: 201 body: raw data']
            ]
          end
        end

        context 'with options' do
          before do
            expect(plugin.client).to receive(:page).with(
              user_id: 'user_123', name: 'pageABC', properties: { active: 'yes', category: 'Prd' },
              integrations: { 'content' => true }, anonymous_id: 'anID'
            ).and_return(response)

            itly.page(
              user_id: 'user_123', category: 'Prd', name: 'pageABC', properties: { active: 'yes' },
              options: { 'segment' => Itly::Plugin::Segment::PageOptions.new(
                integrations: { 'content' => true }, anonymous_id: 'anID'
              ) }
            )
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'segment: load()'],
              ['info', 'page(user_id: user_123, category: Prd, name: pageABC, properties: {:active=>"yes"}, '\
                       'options: {"segment"=>#<Segment::PageOptions callback: nil integrations: {"content"=>true} '\
                       'anonymous_id: anID>})'],
              ['info', 'validate(event: #<Itly::Event: name: page, properties: {:active=>"yes"}>)'],
              ['info', 'segment: page(user_id: user_123, category: Prd, name: pageABC, properties: {:active=>"yes"}, '\
                       'options: #<Segment::PageOptions callback: nil integrations: {"content"=>true} '\
                       'anonymous_id: anID>)']
            ]
          end
        end
      end

      context 'failure' do
        context 'development' do
          before do
            itly.load do |options|
              options.plugins = [plugin]
              options.logger = logger
              options.environment = Itly::Options::Environment::DEVELOPMENT
            end

            expect(plugin.client).to receive(:page)
              .with(user_id: 'user_123', name: 'pageABC', properties: { active: 'yes', category: 'Prd' })
              .and_call_original

            stub_const 'SimpleSegment::Request::BASE_URL', 'not a url'
          end

          it do
            itly.page user_id: 'user_123', category: 'Prd', name: 'pageABC', properties: { active: 'yes' }
          end
        end

        context 'production' do
          before do
            itly.load do |options|
              options.plugins = [plugin]
              options.logger = logger
              options.environment = Itly::Options::Environment::PRODUCTION
            end

            expect(plugin.client).to receive(:page)
              .with(user_id: 'user_123', name: 'pageABC', properties: { active: 'yes', category: 'Prd' })
              .and_call_original

            stub_const 'SimpleSegment::Request::BASE_URL', 'not a url'

            itly.page user_id: 'user_123', category: 'Prd', name: 'pageABC', properties: { active: 'yes' }
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'segment: load()'],
              ['info', 'page(user_id: user_123, category: Prd, name: pageABC, properties: {:active=>"yes"})'],
              ['info', 'validate(event: #<Itly::Event: name: page, properties: {:active=>"yes"}>)'],
              ['info', 'segment: page(user_id: user_123, category: Prd, name: pageABC, properties: {:active=>"yes"})']
            ]
          end
        end
      end
    end

    context 'disabled' do
      let(:plugin) { Itly::Plugin::Segment.new write_key: 'key123', disabled: true }

      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = ::Logger.new logs
        end
      end

      it do
        expect do
          itly.page user_id: 'user_123', category: 'Prd', name: 'pageABC', properties: { active: 'yes' }
        end.not_to raise_error
      end
    end
  end

  describe '#track' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }
    let(:event) { Itly::Event.new name: 'custom_event', properties: { view: 'video' } }

    describe 'enabled' do
      let(:plugin) { Itly::Plugin::Segment.new write_key: 'key123' }
      let(:logger) { ::Logger.new logs }

      context 'success' do
        let(:response) { double 'response', code: '201', body: 'raw data' }

        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = logger
          end
        end

        context 'default' do
          before do
            expect(plugin.client).to receive(:track)
              .with(user_id: 'user_123', event: 'custom_event', properties: { view: 'video' })
              .and_return(response)

            itly.track user_id: 'user_123', event: event
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'segment: load()'],
              ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
              ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
              ['info', 'segment: track(user_id: user_123, event: custom_event, properties: {:view=>"video"})']
            ]
          end
        end

        context 'with callback' do
          before do
            expect(plugin.client).to receive(:track)
              .with(user_id: 'user_123', event: 'custom_event', properties: { view: 'video' })
              .and_return(response)

            itly.track(
              user_id: 'user_123', event: event,
              options: { 'segment' => Itly::Plugin::Segment::TrackOptions.new(
                callback: ->(code, body) { logger.info "from-callback: code: #{code} body: #{body}" }
              ) }
            )
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'segment: load()'],
              ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"}, '\
                       'options: {"segment"=>#<Segment::TrackOptions callback: provided>})'],
              ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
              ['info', 'segment: track(user_id: user_123, event: custom_event, properties: {:view=>"video"}, '\
                       'options: #<Segment::TrackOptions callback: provided>)'],
              ['info', 'from-callback: code: 201 body: raw data']
            ]
          end
        end

        context 'with options' do
          before do
            expect(plugin.client).to receive(:track).with(
              user_id: 'user_123', event: 'custom_event', properties: { view: 'video' },
              integrations: { 'content' => true }, anonymous_id: 'anID'
            ).and_return(response)

            itly.track(
              user_id: 'user_123', event: event,
              options: { 'segment' => Itly::Plugin::Segment::TrackOptions.new(
                integrations: { 'content' => true }, anonymous_id: 'anID'
              ) }
            )
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'segment: load()'],
              ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"}, '\
                       'options: {"segment"=>#<Segment::TrackOptions callback: nil integrations: {"content"=>true} '\
                       'anonymous_id: anID>})'],
              ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
              ['info', 'segment: track(user_id: user_123, event: custom_event, properties: {:view=>"video"}, '\
                       'options: #<Segment::TrackOptions callback: nil integrations: {"content"=>true} '\
                       'anonymous_id: anID>)']
            ]
          end
        end
      end

      context 'failure' do
        context 'development' do
          before do
            itly.load do |options|
              options.plugins = [plugin]
              options.logger = logger
              options.environment = Itly::Options::Environment::DEVELOPMENT
            end

            expect(plugin.client).to receive(:track)
              .with(user_id: 'user_123', event: 'custom_event', properties: { view: 'video' })
              .and_call_original

            stub_const 'SimpleSegment::Request::BASE_URL', 'not a url'
          end

          it do
            itly.track user_id: 'user_123', event: event
          end
        end

        context 'production' do
          before do
            itly.load do |options|
              options.plugins = [plugin]
              options.logger = logger
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
              ['info', 'segment: load()'],
              ['info', 'track(user_id: user_123, event: custom_event, properties: {:view=>"video"})'],
              ['info', 'validate(event: #<Itly::Event: name: custom_event, properties: {:view=>"video"}>)'],
              ['info', 'segment: track(user_id: user_123, event: custom_event, properties: {:view=>"video"})']
            ]
          end
        end
      end
    end

    context 'disabled' do
      let(:plugin) { Itly::Plugin::Segment.new write_key: 'key123', disabled: true }

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
      let(:plugin) { Itly::Plugin::Segment.new write_key: 'key123' }
      let(:logger) { ::Logger.new logs }

      context 'success' do
        let(:response) { double 'response', code: '201', body: 'raw data' }

        before do
          itly.load do |options|
            options.plugins = [plugin]
            options.logger = logger
          end
        end

        context 'default' do
          before do
            expect(plugin.client).to receive(:alias)
              .with(user_id: 'user_123', previous_id: 'old_user')
              .and_return(response)

            itly.alias user_id: 'user_123', previous_id: 'old_user'
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'segment: load()'],
              ['info', 'alias(user_id: user_123, previous_id: old_user)'],
              ['info', 'segment: alias(user_id: user_123, previous_id: old_user)']
            ]
          end
        end

        context 'with callback' do
          before do
            expect(plugin.client).to receive(:alias)
              .with(user_id: 'user_123', previous_id: 'old_user')
              .and_return(response)

            itly.alias(
              user_id: 'user_123', previous_id: 'old_user',
              options: { 'segment' => Itly::Plugin::Segment::AliasOptions.new(
                callback: ->(code, body) { logger.info "from-callback: code: #{code} body: #{body}" }
              ) }
            )
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'segment: load()'],
              ['info', 'alias(user_id: user_123, previous_id: old_user, '\
                       'options: {"segment"=>#<Segment::AliasOptions callback: provided>})'],
              ['info', 'segment: alias(user_id: user_123, previous_id: old_user, '\
                       'options: #<Segment::AliasOptions callback: provided>)'],
              ['info', 'from-callback: code: 201 body: raw data']
            ]
          end
        end

        context 'with options' do
          before do
            expect(plugin.client).to receive(:alias).with(
              user_id: 'user_123', previous_id: 'old_user', integrations: { 'content' => true },
              anonymous_id: 'anID'
            ).and_return(response)

            itly.alias(
              user_id: 'user_123', previous_id: 'old_user',
              options: { 'segment' => Itly::Plugin::Segment::AliasOptions.new(
                integrations: { 'content' => true }, anonymous_id: 'anID'
              ) }
            )
          end

          it do
            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['info', 'segment: load()'],
              ['info', 'alias(user_id: user_123, previous_id: old_user, options: '\
                       '{"segment"=>#<Segment::AliasOptions callback: nil integrations: {"content"=>true} '\
                       'anonymous_id: anID>})'],
              ['info', 'segment: alias(user_id: user_123, previous_id: old_user, '\
                       'options: #<Segment::AliasOptions callback: nil integrations: {"content"=>true} '\
                       'anonymous_id: anID>)']
            ]
          end
        end
      end

      context 'failure' do
        context 'development' do
          before do
            itly.load do |options|
              options.plugins = [plugin]
              options.logger = logger
              options.environment = Itly::Options::Environment::DEVELOPMENT
            end

            expect(plugin.client).to receive(:alias)
              .with(user_id: 'user_123', previous_id: 'old_user')
              .and_call_original

            stub_const 'SimpleSegment::Request::BASE_URL', 'not a url'
          end

          it do
            itly.alias user_id: 'user_123', previous_id: 'old_user'
          end
        end

        context 'production' do
          before do
            itly.load do |options|
              options.plugins = [plugin]
              options.logger = logger
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
              ['info', 'segment: load()'],
              ['info', 'alias(user_id: user_123, previous_id: old_user)'],
              ['info', 'segment: alias(user_id: user_123, previous_id: old_user)']
            ]
          end
        end
      end
    end

    context 'disabled' do
      let(:plugin) { Itly::Plugin::Segment.new write_key: 'key123', disabled: true }

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
      let(:plugin) { Itly::Plugin::Segment.new write_key: 'key123' }

      it do
        expect(plugin.send(:enabled?)).to be(true)
      end
    end

    describe 'disabled' do
      let(:plugin) { Itly::Plugin::Segment.new write_key: 'key123', disabled: true }

      it do
        expect(plugin.send(:enabled?)).to be(false)
      end
    end
  end
end
