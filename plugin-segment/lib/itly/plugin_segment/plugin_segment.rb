# frozen_string_literal: true

require 'itly-sdk'
require 'simple_segment'

class Itly
  ##
  # Segment plugin class for Itly SDK
  #
  # Automatically loaded at runtime in any new +Itly+ object
  #
  class PluginSegment < Plugin
    attr_reader :logger, :client

    ##
    # Initialize Segment::Tracker client
    #
    # Plugin specific options are set when calling Itly#load
    # The option key for +PluginSegment+ is +segment+. For example:
    #
    #     itly = Itly.new
    #     itly.load do |options|
    #       options.plugins.segment = {write_key: 'abc123'}
    #     end
    #
    # Accepted options are:
    # - +write_key+ [Symbol] specify the Segment project token
    #
    def load(options:)
      # Get options
      @logger = options.logger
      plugin_options = get_plugin_options options

      # Log
      logger.info "#{plugin_id}: load()"

      # Configure client
      error_handler = proc do |error_code, error_body, exception, _|
        message = 'The client returned an error.'
        message += " Error code: #{error_code}. " if error_code
        message += " Error body: #{error_body}. " if error_body
        message += " Exception #{exception.class.name}: #{exception.message}." if exception

        raise Itly::RemoteError, message
      end

      @client = ::SimpleSegment::Client.new write_key: plugin_options[:write_key], logger: logger,
        on_error: error_handler
    end

    ##
    # Identify a user
    #
    # Raise an error if the client fails
    #
    # @param [String] user_id: the id of the user in your application
    # @param [Event] properties: the event containing user's traits to pass to your application
    #
    def identify(user_id:, properties:)
      # Log
      logger.info "#{plugin_id}: identify(user_id: #{user_id}, properties: #{properties})"

      # Send through the client
      @client.identify user_id: user_id, traits: properties.properties
    end

    ##
    # Associate a user with their group
    #
    # Raise an error if the client fails
    #
    # @param [String] user_id: the id of the user in your application
    # @param [String] group_id: the id of the group in your application
    # @param [Event] properties: the event containing properties to pass to your application
    #
    def group(user_id:, group_id:, properties:)
      # Log
      logger.info "#{plugin_id}: group(user_id: #{user_id}, group_id: #{group_id}, properties: #{properties})"

      # Send through the client
      @client.group user_id: user_id, group_id: group_id, traits: properties.properties
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
      # Log
      logger.info "#{plugin_id}: track(user_id: #{user_id}, event: #{event.name}, properties: #{event.properties})"

      # Send through the client
      @client.track user_id: user_id, event: event.name, properties: event.properties
    end

    ##
    # Associate one user ID with another (typically a known user ID with an anonymous one).
    #
    # Raise an error if the client fails
    #
    # @param [String] user_id: The ID that the user will be identified by going forward. This is
    #   typically the user's database ID (as opposed to an anonymous ID), or their updated ID
    #   (for example, if the ID is an email address which the user just updated).
    # @param [String] previous_id: The ID the user has been identified by so far.
    #
    def alias(user_id:, previous_id:)
      # Log
      logger.info "#{plugin_id}: alias(user_id: #{user_id}, previous_id: #{previous_id})"

      # Send through the client
      @client.alias user_id: user_id, previous_id: previous_id
    end
  end
end