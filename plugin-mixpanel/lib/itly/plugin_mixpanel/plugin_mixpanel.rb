# frozen_string_literal: true

require 'itly-sdk'
require 'mixpanel-ruby'

class Itly
  ##
  # Mixpanel plugin class for Itly SDK
  #
  # Automatically loaded at runtime in any new +Itly+ object
  #
  class PluginMixpanel < Plugin
    attr_reader :logger, :client

    ##
    # Initialize Mixpanel::Tracker client
    #
    # Plugin specific options are set when calling Itly#load
    # The option key for +PluginMixpanel+ is +mixpanel+. For example:
    #
    #     itly = Itly.new
    #     itly.load do |options|
    #       options.plugins.mixpanel = {project_token: 'abc123'}
    #     end
    #
    # Accepted options are:
    # - +project_token+ [Symbol] specify the Mixpanel project token
    #
    def load(options:)
      # Get options
      @logger = options.logger
      plugin_options = get_plugin_options options

      # Log
      logger.info "#{plugin_id}: load()"

      # Configure client
      @client = ::Mixpanel::Tracker.new plugin_options[:project_token], ErrorHandler.new
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
      @client.people.set user_id, properties.properties
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
      @client.track user_id, event.name, event.properties
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
      @client.alias user_id, previous_id
    end
  end
end
