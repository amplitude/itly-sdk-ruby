# frozen_string_literal: true

require 'itly-sdk'
require 'snowplow-tracker'

class Itly
  class Plugin
    ##
    # Snowplow plugin class for Itly SDK
    #
    class Snowplow < Plugin
      attr_reader :logger, :vendor, :disabled, :client

      ##
      # Instantiate a new Plugin::Snowplow
      #
      # @param [Itly::Plugin::Snowplow::Options] options: the options. See +Itly::Plugin::Snowplow::Options+
      #
      def initialize(options:)
        super()
        @vendor = options.vendor
        @disabled = options.disabled

        emitter = SnowplowTracker::Emitter.new \
          options.endpoint, protocol: options.protocol, method: options.method, buffer_size: options.buffer_size
        @client = SnowplowTracker::Tracker.new emitter
      end

      ##
      # Initialize Snowplow plugin
      #
      # @param [Itly::PluginOptions] options: plugin options
      #
      def load(options:)
        super
        # Get options
        @logger = options.logger

        # Log
        logger&.info "#{id}: load()"

        logger&.info "#{id}: plugin is disabled!" if @disabled
      end

      ##
      # Identify a user
      #
      # Raise an error if the client fails
      #
      # @param [String] user_id: the id of the user in your application
      # @param [Hash] properties: unused
      # @param [Itly::Plugin::Snowplow::IdentifyOptions] options: the plugin specific options
      #
      def identify(user_id:, properties:, options: nil)
        super
        return unless enabled?

        # Log
        logger&.info "#{id}: identify(user_id: #{user_id}, options: #{options})"

        # Send through the client
        client.set_user_id user_id
      end

      ##
      # Track an event
      #
      # Raise an error if the client fails
      #
      # @param [String] user_id: the id of the user in your application
      # @param [Event] event: the Event object to pass to your application
      # @param [Itly::Plugin::Snowplow::IdentifyOptions] options: the plugin specific options
      #
      def track(user_id:, event:, options: nil)
        super
        return unless enabled?

        # Log
        logger&.info "#{id}: track(user_id: #{user_id}, event: #{event.name}, version: #{event.version}, "\
          "properties: #{event.properties}, options: #{options})"

        # Identify the user
        client.set_user_id user_id

        # Send through the client
        schema_version = event.version&.gsub(/\./, '-')
        schema = "iglu:#{vendor}/#{event.name}/jsonschema/#{schema_version}"

        client.track_self_describing_event(
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
