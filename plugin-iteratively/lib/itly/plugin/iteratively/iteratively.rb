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
      # @param [String] api_key: specify the api key
      # @param [Itly::Plugin::Iteratively::Options] options: options object. See +Itly::Plugin::Iteratively::Options+
      #
      def initialize(api_key:, options:)
        super()
        @api_key = api_key
        @url = options.url
        @disabled = options.disabled

        @client_options = {
          flush_queue_size: options.flush_queue_size,
          batch_size: options.batch_size,
          flush_interval_ms: options.flush_interval_ms,
          max_retries: options.max_retries,
          retry_delay_min: options.retry_delay_min,
          retry_delay_max: options.retry_delay_max,
          omit_values: options.omit_values,
          branch: options.branch,
          version: options.version
        }
      end

      ##
      # Initialize IterativelyApi client
      #
      # The plugin is automatically disabled in Production
      #
      # @param [Itly::PluginOptions] options: plugin options
      #
      def load(options:)
        super
        # Get options
        @logger = options.logger

        # Log
        logger&.info "#{id}: load()"

        # Disabled
        @disabled = options.environment == Itly::Options::Environment::PRODUCTION if @disabled.nil?

        if @disabled
          logger&.info "#{id}: plugin is disabled!"
          return
        end

        # Client
        @client_options.merge! url: @url, api_key: @api_key, logger: @logger
        @client = Itly::Plugin::Iteratively::Client.new(**@client_options)
      end

      def post_identify(user_id:, properties:, validation_results:)
        super
        return unless enabled?

        # Log
        logger&.info "#{id}: post_identify(user_id: #{user_id}, properties: #{properties}, "\
          "validation_results: [#{validation_results.collect(&:to_s).join ', '}])"

        client_track Itly::Plugin::Iteratively::TrackType::IDENTIFY, properties, validation_results
      end

      def post_group(user_id:, group_id:, properties:, validation_results:)
        super
        return unless enabled?

        # Log
        logger&.info "#{id}: post_group(user_id: #{user_id}, group_id: #{group_id}, properties: #{properties}, "\
          "validation_results: [#{validation_results.collect(&:to_s).join ', '}])"

        client_track Itly::Plugin::Iteratively::TrackType::GROUP, properties, validation_results
      end

      def post_track(user_id:, event:, validation_results:)
        super
        return unless enabled?

        # Log
        logger&.info "#{id}: post_track(user_id: #{user_id}, event: #{event}, "\
          "validation_results: [#{validation_results.collect(&:to_s).join ', '}])"

        client_track Itly::Plugin::Iteratively::TrackType::TRACK, event, validation_results
      end

      def flush
        @client.flush
      end

      def shutdown(force: false)
        @client.shutdown force: force
      end

      private

      def enabled?
        !@disabled
      end

      def client_track(type, event_or_properties, validations)
        event = event_or_properties.is_a?(Itly::Event) ? event_or_properties : nil
        properties = event_or_properties.is_a?(Hash) ? event_or_properties : nil
        validation = (validations || []).reject(&:valid).first
        @client.track type: type, event: event, properties: properties, validation: validation
      end
    end
  end
end
