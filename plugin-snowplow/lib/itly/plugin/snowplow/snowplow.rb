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
      # @param [String] vendor: the Snowplow vendor
      # @param [Itly::Plugin::Snowplow::Options] options: the options. See +Itly::Plugin::Snowplow::Options+
      #
      def initialize(vendor:, options:)
        super()
        @vendor = vendor
        @disabled = options.disabled

        emitter = SnowplowTracker::Emitter.new \
          endpoint: options.endpoint, options: {
            protocol: options.protocol, method: options.method, buffer_size: options.buffer_size
          }
        @client = SnowplowTracker::Tracker.new emitters: emitter
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
      def identify(user_id:, properties: nil, options: nil)
        super
        return unless enabled?

        # Log
        log = Itly::Loggers.vars_to_log user_id: user_id, options: options
        logger&.info "#{id}: identify(#{log})"

        # Send through the client
        client.set_user_id user_id
      end

      ##
      # Record page views
      #
      # Raise an error if the client fails
      #
      # @param [String] user_id: the id of the user in your application
      # @param [String] category: the category of the page
      # @param [String] name: the name of the page.
      # @param [Hash] properties: the properties to pass to your application
      # @param [Itly::Plugin::Snowplow::PageOptions] options: the plugin specific options
      #
      def page(user_id:, category: nil, name: nil, properties: nil, options: nil)
        super
        return unless enabled?

        # Log
        log = Itly::Loggers.vars_to_log(
          user_id: user_id, category: category, name: name, properties: properties, options: options
        )
        logger&.info "#{id}: page(#{log})"

        # Identify the user
        client.set_user_id user_id

        # Send through the client
        contexts = nil
        if options&.contexts.is_a?(Array) && options.contexts.any?
          contexts = options.contexts.collect(&:to_self_describing_json)
        end

        client.track_screen_view name: name, context: contexts
      end

      ##
      # Track an event
      #
      # Raise an error if the client fails
      #
      # @param [String] user_id: the id of the user in your application
      # @param [Event] event: the Event object to pass to your application
      # @param [Itly::Plugin::Snowplow::TrackOptions] options: the plugin specific options
      #
      def track(user_id:, event:, options: nil)
        super
        return unless enabled?

        # Log
        log = Itly::Loggers.vars_to_log(
          user_id: user_id, event: event&.name, version: event&.version, properties: event&.properties, options: options
        )
        logger&.info "#{id}: track(#{log})"

        # Identify the user
        client.set_user_id user_id

        # Send through the client
        schema_version = event.version&.gsub(/\./, '-')
        schema = "iglu:#{vendor}/#{event.name}/jsonschema/#{schema_version}"

        event_json = SnowplowTracker::SelfDescribingJson.new(
          schema, event.properties
        )

        contexts = nil
        if options&.contexts.is_a?(Array) && options.contexts.any?
          contexts = options.contexts.collect(&:to_self_describing_json)
        end

        client.track_self_describing_event event_json: event_json, context: contexts
      end

      ##
      # Get the plugin ID
      #
      # @return [String] plugin id
      #
      def id
        'snowplow'
      end

      private

      def enabled?
        !@disabled
      end
    end
  end
end
