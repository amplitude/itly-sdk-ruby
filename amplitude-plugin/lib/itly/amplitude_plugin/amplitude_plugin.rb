# frozen_string_literal: true

require 'itly-sdk'
require 'amplitude-api'

class Itly
  ##
  # Amplitude plugin class for Itly SDK
  #
  # Automatically loaded at runtime in any new +Itly+ object
  #
  class AmplitudePlugin < Plugin
    attr_reader :logger

    ##
    # Initialize AmplitudeApi client
    #
    # Plugin specific options are set when calling Itly#load
    # The option key for +AmplitudePlugin+ is +amplitude_plugin+. For examplt:
    #
    #     itly = Itly.new
    #     itly.load do |options|
    #       options.plugins.amplitude_plugin = {api_key: 'abc123'}
    #     end
    #
    # Accepted options are:
    # - +api_key+ [Symbol] specify the Amplitude api key
    #
    def load(options:)
      # Get options
      @logger = options.logger
      plugin_options = get_plugin_options options

      # Log
      logger.info "#{plugin_id}: load()"

      # Configure client
      ::AmplitudeAPI.config.api_key = plugin_options[:api_key]
    end

    ##
    # Identify a user
    #
    # Raise an error if the response if not 200
    #
    # @param [String] user_id: the id of the user in your application
    # @param [Event] properties: the event containing user's traits to pass to your application
    #
    def identify(user_id:, properties:)
      # Log
      logger.info "#{plugin_id}: identify(user_id: #{user_id}, properties: #{properties})"

      # Send through the client
      call_end_point do
        ::AmplitudeAPI.send_identify user_id, nil, properties.properties
      end
    end

    ##
    # Track an event
    #
    # Raise an error if the response if not 200
    #
    # @param [String] user_id: the id of the user in your application
    # @param [Event] event: the Event object to pass to your application
    #
    def track(user_id:, event:)
      # Log
      logger.info "#{plugin_id}: track(user_id: #{user_id}, event: #{event.name}, properties: #{event.properties})"

      # Send through the client
      call_end_point do
        ::AmplitudeAPI.send_event event.name, user_id, nil, event_properties: event.properties
      end
    end

    private

    def call_end_point
      raise 'You need to give a block' unless block_given?

      # Call remote endpoint (Note: the AmplitudeAPI is using Faraday)
      response = yield
      return if response.status == 200

      # Raise in case of error
      message = "The remote end-point returned an error. Response status: #{response.status}. "\
        "Raw body: #{response.body}"
      raise Itly::RemoteError, message
    end
  end
end
