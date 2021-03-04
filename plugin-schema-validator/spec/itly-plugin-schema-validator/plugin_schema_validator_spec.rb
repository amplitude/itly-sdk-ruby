# frozen_string_literal: true

describe Itly::PluginSchemaValidator do
  include RspecLoggerHelpers

  it 'register itself' do
    expect(Itly.registered_plugins).to eq([Itly::PluginSchemaValidator])
  end

  describe 'instance attributes' do
    it 'default values' do
      expect(Itly::PluginSchemaValidator.new.schemas).to eq({})
      expect(Itly::PluginSchemaValidator.new.validators).to eq({})
    end

    it 'can read' do
      expect(Itly::PluginSchemaValidator.new.respond_to?(:logger)).to be(true)
      expect(Itly::PluginSchemaValidator.new.respond_to?(:schemas)).to be(true)
      expect(Itly::PluginSchemaValidator.new.respond_to?(:schemas)).to be(true)
    end

    it 'cannot write' do
      expect(Itly::PluginSchemaValidator.new.respond_to?(:logger=)).to be(false)
      expect(Itly::PluginSchemaValidator.new.respond_to?(:validators=)).to be(false)
      expect(Itly::PluginSchemaValidator.new.respond_to?(:validators=)).to be(false)
    end
  end

  describe '#load' do
    let(:fake_logger) { double 'logger', info: nil }
    let(:itly) { Itly.new }

    before do
      itly.load do |options|
        options.logger = fake_logger
        options.plugins.schema_validator = { schemas: :fake_schema }
      end
    end

    let(:plugin_validator) { itly.instance_variable_get('@plugins_instances').first }

    it do
      expect(plugin_validator.logger).to eq(fake_logger)
      expect(plugin_validator.schemas).to eq(:fake_schema)
    end
  end

  describe '#validate' do
    let(:logs) { StringIO.new }
    let(:itly) { Itly.new }

    let(:schema) do
      {
        '$id' => 'https://iterative.ly/company/77b37977-cb3a-42eb-bce3-09f5f7c3adb7/context',
        '$schema' => 'http://json-schema.org/draft-07/schema#',
        'title' => 'Context', 'description' => '', 'type' => 'object',
        'properties' => {
          'required_string' => {
            'description' => 'description required_string',
            'type' => 'string'
          },
          'optional_enum' => {
            'description' => 'description optional_enum',
            'enum' => ['Value 1', 'Value 2']
          }
        },
        'additionalProperties' => false,
        'required' => ['required_string']
      }
    end

    before do
      itly.load do |options|
        options.logger = ::Logger.new logs
        options.plugins.schema_validator = { schemas: { context: schema } }
      end
    end

    describe 'missing schema definition' do
      let(:event) do
        Itly::Event.new name: 'other_schema', properties: {
          required_string: 'Required string', optional_enum: 'Value 1'
        }
      end

      it do
        itly.validate event: event

        expect_log_lines_to_equal [
          ['info', 'load()'],
          ['info', 'plugin_schema_validator: load()'],
          ['info', 'validate(event: #<Itly::Event: name: other_schema, properties: '\
                   '{:required_string=>"Required string", :optional_enum=>"Value 1"}>)'],
          ['info', 'plugin_schema_validator: validate(event: #<Itly::Event: name: other_schema, '\
                   'properties: {:required_string=>"Required string", :optional_enum=>"Value 1"}>)'],
          ['error', 'Itly Error in Itly::PluginSchemaValidator. Itly::ValidationError: '\
                    'Event \'other_schema\' not found in tracking plan.']
        ]
      end
    end

    describe 'valid' do
      context 'properties with string keys' do
        let(:event) do
          Itly::Event.new name: 'context', properties: {
            'required_string' => 'Required string', 'optional_enum' => 'Value 1'
          }
        end

        it do
          expect(itly.validate(event: event)).to eq([])

          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'plugin_schema_validator: load()'],
            ['info', 'validate(event: #<Itly::Event: name: context, properties: '\
                     '{"required_string"=>"Required string", "optional_enum"=>"Value 1"}>)'],
            ['info', 'plugin_schema_validator: validate(event: #<Itly::Event: name: '\
                     'context, properties: {"required_string"=>"Required string", "optional_enum"=>"Value 1"}>)']
          ]
        end
      end

      context 'properties with symbol keys' do
        let(:event) do
          Itly::Event.new name: 'context', properties: {
            required_string: 'Required string', optional_enum: 'Value 1'
          }
        end

        it do
          expect(itly.validate(event: event)).to eq([])

          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'plugin_schema_validator: load()'],
            ['info', 'validate(event: #<Itly::Event: name: context, properties: '\
                     '{:required_string=>"Required string", :optional_enum=>"Value 1"}>)'],
            ['info', 'plugin_schema_validator: validate(event: #<Itly::Event: name: '\
                     'context, properties: {:required_string=>"Required string", :optional_enum=>"Value 1"}>)']
          ]
        end
      end

      context 'missing optional key' do
        let(:event) { Itly::Event.new name: 'context', properties: { required_string: 'Required string' } }

        it do
          expect(itly.validate(event: event)).to eq([])

          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'plugin_schema_validator: load()'],
            ['info', 'validate(event: #<Itly::Event: name: context, properties: '\
                     '{:required_string=>"Required string"}>)'],
            ['info', 'plugin_schema_validator: validate(event: #<Itly::Event: name: '\
                     'context, properties: {:required_string=>"Required string"}>)']
          ]
        end
      end
    end

    describe 'invalid' do
      context 'missing required value string keys' do
        let(:event) { Itly::Event.new name: 'context', properties: { optional_enum: 'Value 1' } }

        it do
          results = itly.validate event: event
          expect(results.count).to eq(1)

          response = results[0]
          expect(response).to be_a(Itly::ValidationResponse)
          expect(response.valid).to be(false)
          expect(response.plugin_id).to eq('plugin_schema_validator')
          expect(response.message).to eq('Passed in \'context\' properties did not validate against '\
            'your tracking plan. Error: missing_keys: required_string')

          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'plugin_schema_validator: load()'],
            ['info', 'validate(event: #<Itly::Event: name: context, properties: {:optional_enum=>"Value 1"}>)'],
            ['info', 'plugin_schema_validator: validate(event: #<Itly::Event: name: context, properties: '\
                     '{:optional_enum=>"Value 1"}>)']
          ]
        end
      end

      context 'unexpected enum value' do
        let(:event) do
          Itly::Event.new name: 'context', properties: {
            required_string: 'Required string', optional_enum: 'Wrong value'
          }
        end

        it do
          results = itly.validate event: event
          expect(results.count).to eq(1)

          response = results[0]
          expect(response).to be_a(Itly::ValidationResponse)
          expect(response.valid).to be(false)
          expect(response.plugin_id).to eq('plugin_schema_validator')
          expect(response.message).to eq('Passed in \'context\' properties did not validate '\
            'against your tracking plan. Error: Wrong value /optional_enum')

          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'plugin_schema_validator: load()'],
            ['info', 'validate(event: #<Itly::Event: name: context, properties: '\
                     '{:required_string=>"Required string", :optional_enum=>"Wrong value"}>)'],
            ['info', 'plugin_schema_validator: validate(event: #<Itly::Event: name: '\
                     'context, properties: {:required_string=>"Required string", :optional_enum=>"Wrong value"}>)']
          ]
        end
      end

      context 'incorrect data type' do
        let(:event) do
          Itly::Event.new name: 'context', properties: {
            required_string: 17, optional_enum: 'Value 1'
          }
        end

        it do
          results = itly.validate event: event
          expect(results.count).to eq(1)

          response = results[0]
          expect(response).to be_a(Itly::ValidationResponse)
          expect(response.valid).to be(false)
          expect(response.plugin_id).to eq('plugin_schema_validator')
          expect(response.message).to eq('Passed in \'context\' properties did not validate against your '\
            'tracking plan. Error: 17 /required_string')

          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'plugin_schema_validator: load()'],
            ['info', 'validate(event: #<Itly::Event: name: context, properties: {:required_string=>17, '\
                     ':optional_enum=>"Value 1"}>)'],
            ['info', 'plugin_schema_validator: validate(event: #<Itly::Event: name: context, properties: '\
                     '{:required_string=>17, :optional_enum=>"Value 1"}>)']
          ]
        end
      end
    end
  end

  describe '#return_validation_responses' do
    let(:event) { Itly::Event.new name: 'context', properties: {} }
    let(:plugin) { Itly::PluginSchemaValidator.new }

    it 'empty' do
      expect(plugin.send(:return_validation_responses, event, [])).to be(nil)
    end

    it 'with a detail' do
      result = [
        { 'details' => { 'field' => %w[message1 message2] } }
      ]

      response = plugin.send :return_validation_responses, event, result
      expect(response).to be_a(Itly::ValidationResponse)
      expect(response.valid).to be(false)
      expect(response.plugin_id).to eq('plugin_schema_validator')
      expect(response.message).to eq('Passed in \'context\' properties did not validate against your '\
        'tracking plan. Error: field: message1, message2')
    end

    it 'with details' do
      result = [
        { 'details' => { 'field' => %w[message1 message2], 'data' => ['more info'] } }
      ]

      response = plugin.send :return_validation_responses, event, result
      expect(response).to be_a(Itly::ValidationResponse)
      expect(response.valid).to be(false)
      expect(response.plugin_id).to eq('plugin_schema_validator')
      expect(response.message).to eq('Passed in \'context\' properties did not validate against your '\
        'tracking plan. Error: field: message1, message2. data: more info')
    end

    it 'with a data' do
      result = [
        { 'data' => 'error_type', 'data_pointer' => 'error_details' }
      ]

      response = plugin.send :return_validation_responses, event, result
      expect(response).to be_a(Itly::ValidationResponse)
      expect(response.valid).to be(false)
      expect(response.plugin_id).to eq('plugin_schema_validator')
      expect(response.message).to eq('Passed in \'context\' properties did not validate against your '\
        'tracking plan. Error: error_type error_details')
    end

    it 'with multiple errors' do
      result = [
        { 'details' => { 'field1' => %w[message1 message2] } },
        { 'details' => { 'field2' => ['message3'] } }
      ]

      response = plugin.send :return_validation_responses, event, result
      expect(response).to be_a(Itly::ValidationResponse)
      expect(response.valid).to be(false)
      expect(response.plugin_id).to eq('plugin_schema_validator')
      expect(response.message).to eq('Passed in \'context\' properties did not validate against your '\
        'tracking plan. Errors: field1: message1, message2. field2: message3')
    end
  end

  describe '#deeply_stringify_keys' do
    let(:plugin) { Itly::PluginSchemaValidator.new }

    it 'empty' do
      expect(plugin.send(:deeply_stringify_keys, {})).to eq({})
    end

    it 'default' do
      hash = { 'a' => 1, b: 2,
               c: [3, { 'd' => 4, e: { f: { g: 5 } } }] }
      expected = { 'a' => 1, 'b' => 2,
                   'c' => [3, { 'd' => 4, 'e' => { 'f' => { 'g' => 5 } } }] }

      expect(plugin.send(:deeply_stringify_keys, hash)).to eq(expected)
    end
  end

  describe '#hash_to_message' do
    let(:plugin) { Itly::PluginSchemaValidator.new }

    it 'empty' do
      expect(plugin.send(:hash_to_message, {})).to eq('')
    end

    it 'default' do
      hash = {
        'First' => %w[ValueA ValueB],
        'Second' => %w[ValueC]
      }

      expect(plugin.send(:hash_to_message, hash)).to eq('First: ValueA, ValueB. Second: ValueC')
    end
  end
end
