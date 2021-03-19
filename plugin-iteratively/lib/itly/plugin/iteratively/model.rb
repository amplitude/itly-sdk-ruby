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
      class Model
        attr_reader :type, :date_sent, :event_id, :event_chema_version, :event_name,
          :properties, :valid, :validation

        def initialize(omit_values:, type:, event:, validation: nil)
          @omit_values = omit_values
          @type = type
          @date_sent = Time.now.utc.iso8601
          @event_id = event.id
          @event_chema_version = event.version
          @event_name = event.name
          @properties = event.properties
          @valid = validation ? validation.valid : nil
          @validation = validation ? validation.message : nil

          if @omit_values
            @properties = @properties.each_with_object({}) { |(key, _), hash| hash[key] = '' }
          end
        end

        def to_json(*_)
          {
            type: @type,
            dateSent: @date_sent,
            eventId: @event_id,
            eventChemaVersion: @event_chema_version,
            eventName: @event_name,
            properties: @properties,
            valid: @valid,
            validation: @validation
          }.to_json
        end

        def to_s
          "#<#{self.class.name}: type: #{@type} date_sent: #{@date_sent} event_id: #{@event_id} "\
            "event_chema_version: #{@event_chema_version} event_name: #{@event_name} "\
            "properties: #{@properties} valid: #{@valid} validation: #{@validation}>"
        end
      end
    end
  end
end
