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
        super
        # Get options
        @logger = options.logger

        # Log
        @logger&.info "#{id}: load()"

        if @disabled
          @logger&.info "#{id}: plugin is disabled!"
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
      # @param [Itly::Plugin::Segment::IdentifyOptions] options: the plugin specific options
      #
      def identify(user_id:, properties: nil, options: nil)
        super
        return unless enabled?

        # Log
        log = Itly::Loggers.vars_to_log user_id: user_id, properties: properties, options: options
        @logger&.info "#{id}: identify(#{log})"

        # Send through the client
        payload = { user_id: user_id }
        payload.merge! traits: properties.dup if properties
        payload.merge! options.to_hash if options

        call_end_point(options&.callback) do
          @client.identify(**payload)
        end
      end

      ##
      # Associate a user with their group
      #
      # Raise an error if the client fails
      #
      # @param [String] user_id: the id of the user in your application
      # @param [String] group_id: the id of the group in your application
      # @param [Hash] properties: the properties to pass to your application
      # @param [Itly::Plugin::Segment::GroupOptions] options: the plugin specific options
      #
      def group(user_id:, group_id:, properties: nil, options: nil)
        super
        return unless enabled?

        # Log
        log = Itly::Loggers.vars_to_log(
          user_id: user_id, group_id: group_id, properties: properties, options: options
        )
        @logger&.info "#{id}: group(#{log})"

        # Send through the client
        payload = { user_id: user_id, group_id: group_id }
        payload.merge! traits: properties.dup if properties
        payload.merge! options.to_hash if options

        call_end_point(options&.callback) do
          @client.group(**payload)
        end
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
      # @param [Itly::Plugin::Segment::PageOptions] options: the plugin specific options
      #
      def page(user_id:, category: nil, name: nil, properties: nil, options: nil)
        super
        return unless enabled?

        # Log
        log = Itly::Loggers.vars_to_log(
          user_id: user_id, category: category, name: name, properties: properties, options: options
        )
        @logger&.info "#{id}: page(#{log})"

        # Send through the client
        payload = { user_id: user_id }
        payload.merge! name: name if name
        payload.merge! options.to_hash if options
        if properties && category
          payload.merge! properties: properties.dup.merge(category: category)
        elsif properties
          payload.merge! properties: properties.dup
        elsif category
          payload.merge! properties: { category: category }
        end

        call_end_point(options&.callback) do
          @client.page(**payload)
        end
      end

      ##
      # Track an event
      #
      # Raise an error if the client fails
      #
      # @param [String] user_id: the id of the user in your application
      # @param [Event] event: the Event object to pass to your application
      # @param [Itly::Plugin::Segment::TrackOptions] options: the plugin specific options
      #
      def track(user_id:, event:, options: nil)
        super
        return unless enabled?

        # Log
        log = Itly::Loggers.vars_to_log(
          user_id: user_id, event: event&.name, properties: event&.properties, options: options
        )
        @logger&.info "#{id}: track(#{log})"

        # Send through the client
        payload = { user_id: user_id, event: event.name, properties: event.properties.dup }
        payload.merge! options.to_hash if options

        call_end_point(options&.callback) do
          @client.track(**payload)
        end
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
      # @param [Itly::Plugin::Segment::AliasOptions] options: the plugin specific options
      #
      def alias(user_id:, previous_id:, options: nil)
        super
        return unless enabled?

        # Log
        log = Itly::Loggers.vars_to_log(
          user_id: user_id, previous_id: previous_id, options: options
        )
        @logger&.info "#{id}: alias(#{log})"

        # Send through the client
        payload = { user_id: user_id, previous_id: previous_id }
        payload.merge! options.to_hash if options

        call_end_point(options&.callback) do
          @client.alias(**payload)
        end
      end

      ##
      # Get the plugin ID
      #
      # @return [String] plugin id
      #
      def id
        'segment'
      end

      private

      def enabled?
        !@disabled
      end

      def call_end_point(callback)
        raise 'You need to give a block' unless block_given?

        # Call remote endpoint (Note: the Segment client returns a Net::HTTPResponse)
        response = yield

        # yield to the callback passed in to options
        callback&.call(response.code.to_i, response.body)
      end
    end
  end
end
