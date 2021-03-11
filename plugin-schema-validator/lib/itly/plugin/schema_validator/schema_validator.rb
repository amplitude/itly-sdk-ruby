# frozen_string_literal: true

require 'itly-sdk'
require 'json_schemer'

class Itly
  class Plugin
    ##
    # Schema Validator plugin class for Itly SDK
    #
    # Automatically loaded at runtime in any new +Itly+ object
    #
    class SchemaValidator < Plugin
      attr_reader :logger, :schemas, :validators

      ##
      # Instantiate a new Plugin::SchemaValidator
      #
      # @param [Hash] schemas: schemas for validation. Example:
      #
      #     Plugin::SchemaValidator.new schema: {
      #       schema_1: {field: 'value, ...},
      #       schema_2: {field: 'value, ...}
      #     }
      #
      def initialize(schemas:)
        super()
        @schemas = schemas
        @validators = {}
      end

      ##
      # Initialize the Plugin::SchemaValidator object
      #
      def load(options:)
        # Get options
        @logger = options.logger

        # Log
        logger.info "#{plugin_id}: load()"
      end

      ##
      # Validate an Event
      #
      # Call +event+ on all plugins and collect their return values.
      #
      # @param [Event] event: the event to validate
      #
      # @return [Itly::ValidationResponse] a Itly::ValidationResponse object generated
      # by the plugins or nil to indicate that there were no error
      #
      def validate(event:)
        # Log
        logger.info "#{plugin_id}: validate(event: #{event})"

        # Check that we have a schema for this event
        if @schemas[event.name.to_sym].nil?
          raise Itly::ValidationError, "Event '#{event.name}' not found in tracking plan."
        end

        # Lazily initialize and cache validator
        @validators[event.name.to_sym] ||= JSONSchemer.schema(@schemas[event.name.to_sym])

        # Validation
        properties = deeply_stringify_keys event.properties
        result = @validators[event.name.to_sym].validate properties

        return_validation_responses event, result
      end

      private

      def return_validation_responses(event, result)
        return if result.count.zero?

        message = "Passed in '#{event.name}' properties did not validate against your tracking plan. "\
          "Error#{'s' if result.count > 1}: "

        message += result.collect do |error|
          if error['details']
            hash_to_message error['details']
          else
            "#{error['data']} #{error['data_pointer']}"
          end
        end.join '. '

        Itly::ValidationResponse.new valid: false, plugin_id: plugin_id, message: message
      end

      def deeply_stringify_keys(hash)
        stringified_hash = {}
        hash.each do |k, v|
          stringified_hash[k.to_s] = \
            case v
            when Hash
              deeply_stringify_keys(v)
            when Array
              v.map { |i| i.is_a?(Hash) ? deeply_stringify_keys(i) : i }
            else
              v
            end
        end
        stringified_hash
      end

      def hash_to_message(hash)
        hash.collect do |k, v|
          "#{k}: #{v.join ', '}"
        end.join '. '
      end
    end
  end
end
