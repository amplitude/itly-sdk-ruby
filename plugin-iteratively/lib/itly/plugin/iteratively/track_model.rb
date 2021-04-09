# frozen_string_literal: true

require 'time'
require 'json'
require 'itly-sdk'

class Itly
  class Plugin
    class Iteratively
      ##
      # Data model for HTTP client buffering
      #
      class TrackModel
        attr_reader :type, :date_sent, :event_id, :event_schema_version, :event_name,
          :properties, :valid, :validation

        def initialize(type:, event:, properties:, validation: nil, omit_values: false)
          @omit_values = omit_values
          @type = type
          @date_sent = Time.now.utc.iso8601
          @event_id = event&.id
          @event_schema_version = event&.version
          @event_name = event&.name
          @properties = event&.properties || properties
          @valid = validation ? validation.valid : true
          @validation = { details: validation ? validation.message : '' }

          @properties = @properties.transform_values { |_| '' } if @omit_values
        end

        def to_json(*_)
          {
            type: @type,
            dateSent: @date_sent,
            eventId: @event_id,
            eventSchemaVersion: @event_schema_version,
            eventName: @event_name,
            properties: @properties,
            valid: @valid,
            validation: @validation
          }.to_json
        end

        def to_s
          "#<#{self.class.name}: type: #{@type} date_sent: #{@date_sent} event_id: #{@event_id} "\
            "event_schema_version: #{@event_schema_version} event_name: #{@event_name} "\
            "properties: #{@properties} valid: #{@valid} validation: #{@validation}>"
        end
      end
    end
  end
end
