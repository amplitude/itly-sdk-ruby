# frozen_string_literal: true

require 'itly-sdk'
require 'amplitude-api'

class Itly
  class Plugin
    ##
    # Amplitude plugin class for Itly SDK
    #
    class Amplitude < Plugin
      attr_reader :logger, :disabled

      ##
      # Instantiate a new Plugin::Amplitude
      #
      # @param [String] api_key: specify the Amplitude api key
      # @param [TrueClass/FalseClass] disabled: set to true to disable the plugin. Default to false
      #
      def initialize(api_key:, disabled: false)
        super()
        @disabled = disabled

        ::AmplitudeAPI.config.api_key = api_key
      end

      ##
      # Initialize AmplitudeApi client
      #
      # @param [Itly::PluginOptions] options: plugins options
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
      # Raise an error if the response is not 200
      #
      # @param [String] user_id: the id of the user in your application
      # @param [Hash] properties: the properties containing user's traits to pass to your application
      # @param [Itly::Plugin::Amplitude::IdentifyOptions] options: the plugin specific options
      #
      def identify(user_id:, properties: nil, options: nil)
        super
        return unless enabled?

        # Log
        log = Itly::Loggers.vars_to_log user_id: user_id, properties: properties, options: options
        logger&.info "#{id}: identify(#{log})"

        # Send through the client
        payload = {}
        payload.merge! options.to_hash if options
        payload.merge! properties if properties

        call_end_point(options&.callback) do
          ::AmplitudeAPI.send_identify user_id, nil, payload
        end
      end

      ##
      # Track an event
      #
      # Raise an error if the response is not 200
      #
      # @param [String] user_id: the id of the user in your application
      # @param [Event] event: the Event object to pass to your application
      # @param [Itly::Plugin::Amplitude::TrackOptions] options: the plugin specific options
      #
      def track(user_id:, event:, options: nil)
        super
        return unless enabled?

        # Log
        log = Itly::Loggers.vars_to_log(
          user_id: user_id, event: event&.name, properties: event&.properties, options: options
        )
        logger&.info "#{id}: track(#{log})"

        # Send through the client
        call_end_point(options&.callback) do
          ::AmplitudeAPI.track ::AmplitudeAPI::Event.new(
            user_id: user_id,
            event_type: event.name,
            event_properties: event.properties,
            **(options&.to_hash || {})
          )
        end
      end

      ##
      # Get the plugin ID
      #
      # @return [String] plugin id
      #
      def id
        'amplitude'
      end

      private

      def enabled?
        !@disabled
      end

      def call_end_point(callback)
        raise 'You need to give a block' unless block_given?

        # Call remote endpoint (Note: the AmplitudeAPI is using Faraday)
        response = yield

        # yield to the callback passed in to options
        callback&.call(response.status, response.body)

        # Return in case of success
        return if response.status >= 200 && response.status < 300

        # Raise in case of error
        message = "The remote end-point returned an error. Response status: #{response.status}. "\
          "Raw body: #{response.body}"
        raise Itly::RemoteError, message
      end
    end
  end
end
