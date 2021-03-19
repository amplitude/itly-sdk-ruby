# frozen_string_literal: true

require 'itly-sdk'

class Itly
  class Plugin
    ##
    # Iteratively plugin class for Itly SDK
    #
    # Automatically loaded at runtime in any new +Itly+ object
    #
    class Iteratively < Plugin
      attr_reader :logger, :disabled, :client, :url, :api_key

      ##
      # Instantiate a new Plugin::Iteratively
      #
      # @param [String] url: specify the url to push events to
      # @param [String] api_key: specify the api key
      # @param [TrueClass/FalseClass] disabled: set to true to disable the Iteratively plugin.
      #   Default to +true+ in production environment, to +false+ otherwise
      # @param [Integer] buffer_size (optional): Number of event in the buffer before
      #   a flush is triggered. Default: 10
      # @param [Integer] max_retries (optional): Number of retries for pushing
      #   events to the server. Default: 25
      # @param [Float] retry_delay_min: Minimum delay between retries in seconds. Default: 10.0
      # @param [Float] retry_delay_max: Maximum delay between retries in seconds. Default: 3600.0 (1 hour)
      # @param [TrueClass/FalseClass] omit_values: set to true to send emty data. Default to false
      #
      # rubocop:disable Metrics/ParameterLists
      def initialize(
        url:, api_key:, disabled: nil, buffer_size: 10, max_retries: 25, retry_delay_min: 10.0, 
        retry_delay_max: 3600.0, omit_values: false
      )
        super()
        @url = url
        @api_key = api_key
        @disabled = disabled

        @client_options = {
          buffer_size: buffer_size,
          max_retries: max_retries,
          retry_delay_min: retry_delay_min,
          retry_delay_max: retry_delay_max,
          omit_values: omit_values
        }
      end
      # rubocop:enable Metrics/ParameterLists

      ##
      # Initialize IterativelyApi client
      #
      # The plugin is automatically disabled in Production
      #
      def load(options:)
        # Get options
        @logger = options.logger

        # Log
        logger.info "#{plugin_id}: load()"

        # Disabled
        if @disabled.nil?
          @disabled = options.environment == Itly::Options::Environment::PRODUCTION
        end

        if @disabled
          logger.info "#{plugin_id}: plugin is disabled!"
          return
        end

        # Client
        @client_options.merge! url: @url, api_key: @api_key, logger: @logger
        @client = Itly::Plugin::Iteratively::Client.new(**@client_options)
      end

      def post_identify(user_id:, properties:, validation_results:)
        return unless enabled?

        # Log
        logger.info "#{plugin_id}: post_identify(user_id: #{user_id}, properties: #{properties}, "\
          "validation_results: [#{validation_results.collect(&:to_s).join ', '}])"

        client_track Itly::Plugin::Iteratively::TrackType::IDENTIFY, properties, validation_results
      end

      def post_group(user_id:, group_id:, properties:, validation_results:)
        return unless enabled?

        # Log
        logger.info "#{plugin_id}: post_group(user_id: #{user_id}, group_id: #{group_id}, properties: #{properties}, "\
          "validation_results: [#{validation_results.collect(&:to_s).join ', '}])"

        client_track Itly::Plugin::Iteratively::TrackType::GROUP, properties, validation_results
      end

      def post_track(user_id:, event:, validation_results:)
        return unless enabled?

        # Log
        logger.info "#{plugin_id}: post_track(user_id: #{user_id}, event: #{event}, "\
          "validation_results: [#{validation_results.collect(&:to_s).join ', '}])"

        client_track Itly::Plugin::Iteratively::TrackType::TRACK, event, validation_results
      end

      def flush
        @client.flush
      end

      def shutdown
        @client.shutdown
      end

      private

      def enabled?
        !@disabled
      end

      def client_track(type, event, validations)
        validation = (validations || []).reject(&:valid).first
        @client.track type: type, event: event, validation: validation
      end
    end
  end
end
