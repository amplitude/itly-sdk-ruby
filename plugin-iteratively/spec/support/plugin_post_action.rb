# frozen_string_literal: true

shared_examples 'plugin post action' do |action:, params:|
  let(:logs) { StringIO.new }
  let(:plugin) { Itly::Plugin::Iteratively.new url: 'http://url', api_key: 'key123' }
  let(:itly) { Itly.new }

  context 'success' do
    let(:expected_event) { Itly::Event.new name: action.to_s, properties: { with: 'data' } }

    before do
      itly.load do |options|
        options.plugins = [plugin]
        options.logger = ::Logger.new logs
      end

      expect(plugin).to receive(:client_track).with(action.to_s, expected_event, [])

      itly.send action, **params
    end

    it do
      post_action_log = properties_to_log params.merge \
        properties: "#<Itly::Event: name: #{action}, properties: {:with=>\"data\"}>"

      expect_log_lines_to_equal [
        ['info', 'load()'],
        ['warn', 'Environment not specified. Automatically set to development'],
        ['info', 'plugin-iteratively: load()'],
        ['info', "#{action}(#{properties_to_log params})"],
        ['info', "validate(event: #<Itly::Event: name: #{action}, properties: {:with=>\"data\"}>)"],
        ['info', "plugin-iteratively: post_#{action}(#{post_action_log}, validation_results: [])"]
      ]
    end
  end

  context 'with validation messages' do
    let(:expected_event) { Itly::Event.new name: action.to_s, properties: { with: 'data' } }
    let(:response) { Itly::ValidationResponse.new valid: true, plugin_id: 'test-plg' }
    let(:validator) { Itly::Plugin.new }

    before do
      expect(validator).to receive(:validate).once.with(event: expected_event).and_return(response)
      expect(validator).not_to receive(:validate)

      itly.load do |options|
        options.plugins = [plugin, validator]
        options.logger = ::Logger.new logs
      end

      expect(plugin).to receive(:client_track).with(action.to_s, expected_event, [response])

      itly.send action, **params
    end

    it do
      post_action_log = properties_to_log params.merge \
        properties: "#<Itly::Event: name: #{action}, properties: {:with=>\"data\"}>"

      expect_log_lines_to_equal [
        ['info', 'load()'],
        ['warn', 'Environment not specified. Automatically set to development'],
        ['info', 'plugin-iteratively: load()'],
        ['info', "#{action}(#{properties_to_log params})"],
        ['info', "validate(event: #<Itly::Event: name: #{action}, properties: {:with=>\"data\"}>)"],
        ['info', "plugin-iteratively: post_#{action}(#{post_action_log}, validation_results: "\
                 '[#<Itly::ValidationResponse: valid: true, plugin_id: test-plg, message: >])']
      ]
    end
  end

  context 'disabled' do
    before do
      itly.load do |options|
        options.plugins = [plugin]
        options.logger = ::Logger.new logs
        options.environment = Itly::Options::Environment::PRODUCTION
      end

      expect(plugin).not_to receive(:client_track)

      itly.send action, **params
    end

    it do
      expect_log_lines_to_equal [
        ['info', 'load()'],
        ['info', 'plugin-iteratively: load()'],
        ['info', 'plugin-iteratively: plugin is disabled!'],
        ['info', "#{action}(#{properties_to_log params})"],
        ['info', "validate(event: #<Itly::Event: name: #{action}, properties: {:with=>\"data\"}>)"]
      ]
    end
  end

  context 'failure' do
    before do
      itly.load do |options|
        options.plugins = [plugin]
        options.logger = ::Logger.new logs
        options.environment = Itly::Options::Environment::DEVELOPMENT
      end

      expect(plugin.client).to receive(:track).and_raise('Testing')
    end

    it do
      expect do
        itly.send action, **params
      end.to raise_error(RuntimeError, 'Testing')
    end
  end
end
