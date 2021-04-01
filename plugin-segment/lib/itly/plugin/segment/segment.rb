# frozen_string_literal: true

require 'itly-sdk'
require 'simple_segment'

class Itly
  class Plugin
    ##
    # Segment plugin class for Itly SDK
    #
    # Automatically loaded at runtime in any new +Itly+ object
    #
    class Segment < Plugin
      attr_reader :client, :disabled

      ##
      # Instantiate a new Plugin::Segment
      #
      # @param [String] write_key: specify the Segment write key
      # @param [TrueClass/FalseClass] disabled: set to true to disable the plugin. Default to false
      #
      def initialize(write_key:, disabled: false)
        super()
        @write_key = write_key
        @disabled = disabled
      end

      ##
      # Initialize Segment::Tracker client
      #
      # @param [Itly::PluginOptions] options: plugin options
      #
      def load(options:)
        # Get options
        @logger = options.logger

        # Log
        @logger&.info "#{plugin_id}: load()"

        if @disabled
          @logger&.info "#{plugin_id}: plugin is disabled!"
          return
        end

        # Configure client
        error_handler = proc do |error_code, error_body, exception, _|
          message = 'The client returned an error.'
          message += " Error code: #{error_code}. " if error_code
          message += " Error body: #{error_body}. " if error_body
          message += " Exception #{exception.class.name}: #{exception.message}." if exception

          raise Itly::RemoteError, message
        end

        @client = ::SimpleSegment::Client.new \
          write_key: @write_key, logger: @logger,
          on_error: error_handler
      end

      ##
      # Identify a user
      #
      # Raise an error if the client fails
      #
      # @param [String] user_id: the id of the user in your application
      # @param [Hash] properties: the properties containing user's traits to pass to your application
      #
      def identify(user_id:, properties:)
        return unless enabled?

        # Log
        @logger&.info "#{plugin_id}: identify(user_id: #{user_id}, properties: #{properties})"

        # Send through the client
        @client.identify user_id: user_id, traits: properties
      end

      ##
      # Associate a user with their group
      #
      # Raise an error if the client fails
      #
      # @param [String] user_id: the id of the user in your application
      # @param [String] group_id: the id of the group in your application
      # @param [Hash] properties: the properties to pass to your application
      #
      def group(user_id:, group_id:, properties:)
        return unless enabled?

        # Log
        @logger&.info "#{plugin_id}: group(user_id: #{user_id}, group_id: #{group_id}, properties: #{properties})"

        # Send through the client
        @client.group user_id: user_id, group_id: group_id, traits: properties
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
        @logger&.info "#{plugin_id}: track(user_id: #{user_id}, event: #{event.name}, properties: #{event.properties})"

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
        return unless enabled?

        # Log
        @logger&.info "#{plugin_id}: alias(user_id: #{user_id}, previous_id: #{previous_id})"

        # Send through the client
        @client.alias user_id: user_id, previous_id: previous_id
      end

      private

      def enabled?
        !@disabled
      end
    end
  end
end
