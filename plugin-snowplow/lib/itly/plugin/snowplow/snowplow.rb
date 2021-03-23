# frozen_string_literal: true

require 'itly-sdk'
require 'snowplow-tracker'

class Itly
  class Plugin
    ##
    # Snowplow plugin class for Itly SDK
    #
    class Snowplow < Plugin
      attr_reader :logger, :vendor, :disabled, :tracker

      ##
      # Instantiate a new Plugin::Snowplow
      #
      # @param [String] endpoint: specify the Snowplow endpoint
      # @param [String] vendor: specify the Snowplow vendor
      # @param [TrueClass/FalseClass] disabled: set to true to disable the plugin. Default to false
      #
      def initialize(endpoint:, vendor:, disabled: false)
        super()
        @vendor = vendor
        @disabled = disabled

        emitter = SnowplowTracker::Emitter.new endpoint
        @tracker = SnowplowTracker::Tracker.new emitter
      end

      ##
      # Initialize Snowplow plugin
      #
      # @param [Itly::PluginOptions] options: plugin options
      #
      def load(options:)
        # Get options
        @logger = options.logger

        # Log
        logger.info "#{plugin_id}: load()"

        logger.info "#{plugin_id}: plugin is disabled!" if @disabled
      end

      ##
      # Identify a user
      #
      # Raise an error if the client fails
      #
      # @param [String] user_id: the id of the user in your application
      # @param [Event] properties: unused
      #
      def identify(user_id:, properties:)
        return unless enabled?

        # Log
        logger.info "#{plugin_id}: identify(user_id: #{user_id})"

        # Send through the client
        @tracker.set_user_id user_id
      end

      ##
      # Track an event
      #
      # Raise an error if the client fails
      #
      # @param [String] user_id: the id of the user in your application
      # @param [Event] event: the Event object to pass to your application
      #
      def track(user_id:, event:)
        return unless enabled?

        # Log
        logger.info "#{plugin_id}: track(user_id: #{user_id}, event: #{event.name}, version: #{event.version}, "\
          "properties: #{event.properties})"

        # Send through the client
        schema_version = event.version&.gsub(/\./, '-')
        schema = "iglu:#{vendor}/#{event.name}/jsonschema/#{schema_version}"

        tracker.track_self_describing_event(
          SnowplowTracker::SelfDescribingJson.new(
            schema, event.properties
          )
        )
      end

      private

      def enabled?
        !@disabled
      end
    end
  end
end
