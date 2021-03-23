# frozen_string_literal: true

require 'itly-sdk'
require 'mixpanel-ruby'

class Itly
  class Plugin
    ##
    # Mixpanel plugin class for Itly SDK
    #
    # Automatically loaded at runtime in any new +Itly+ object
    #
    class Mixpanel < Plugin
      attr_reader :logger, :client, :project_token, :disabled

      ##
      # Instantiate a new Plugin::Mixpanel
      #
      # @param [String] project_token: specify the Mixpanel project token
      # @param [TrueClass/FalseClass] disabled: set to true to disable the plugin. Default to false
      #
      def initialize(project_token:, disabled: false)
        super()
        @project_token = project_token
        @disabled = disabled
      end

      ##
      # Initialize Mixpanel::Tracker client
      #
      # @param [Itly::PluginOptions] options: plugin options
      #
      def load(options:)
        # Get options
        @logger = options.logger

        # Log
        logger.info "#{plugin_id}: load()"

        if @disabled
          logger.info "#{plugin_id}: plugin is disabled!"
          return
        end

        # Configure client
        @client = ::Mixpanel::Tracker.new @project_token, ErrorHandler.new
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
        return unless enabled?

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
        return unless enabled?

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
        return unless enabled?

        # Log
        logger.info "#{plugin_id}: alias(user_id: #{user_id}, previous_id: #{previous_id})"

        # Send through the client
        @client.alias user_id, previous_id
      end

      private

      def enabled?
        !@disabled
      end
    end
  end
end
