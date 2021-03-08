# frozen_string_literal: true

require 'itly-sdk'

class Itly
  ##
  # Iteratively plugin class for Itly SDK
  #
  # Automatically loaded at runtime in any new +Itly+ object
  #
  class PluginIteratively < Plugin
    attr_reader :logger, :disabled, :client, :url, :api_key

    ##
    # Instantiate a new PluginIteratively
    #
    # @param [String] url: specify the url to push events to
    # @param [String] api_key: specify the api key
    #
    def initialize(url:, api_key:)
      super()
      @url = url
      @api_key = api_key
    end

    ##
    # Initialize IterativelyApi client
    #
    def load(options:)
      # Get options
      @logger = options.logger

      # Log
      logger.info "#{plugin_id}: load()"

      # Disabled
      @disabled = options.disabled ||
                  options.environment == Itly::Options::Environment::PRODUCTION

      if @disabled
        logger.info "#{plugin_id}: plugin is disabled!"
        return
      end

      # Client
      @client = Itly::PluginIteratively::Client.new url: @url, api_key: @api_key
    end

    def post_identify(user_id:, properties:, validation_results:)
      return unless enabled?

      # Log
      logger.info "#{plugin_id}: post_identify(user_id: #{user_id}, properties: #{properties}, "\
        "validation_results: [#{validation_results.collect(&:to_s).join ', '}])"

      client_track Itly::PluginIteratively::TrackType::IDENTIFY, properties, validation_results
    end

    def post_group(user_id:, group_id:, properties:, validation_results:)
      return unless enabled?

      # Log
      logger.info "#{plugin_id}: post_group(user_id: #{user_id}, group_id: #{group_id}, properties: #{properties}, "\
        "validation_results: [#{validation_results.collect(&:to_s).join ', '}])"

      client_track Itly::PluginIteratively::TrackType::GROUP, properties, validation_results
    end

    def post_track(user_id:, event:, validation_results:)
      return unless enabled?

      # Log
      logger.info "#{plugin_id}: post_track(user_id: #{user_id}, event: #{event}, "\
        "validation_results: [#{validation_results.collect(&:to_s).join ', '}])"

      client_track Itly::PluginIteratively::TrackType::TRACK, event, validation_results
    end

    # Shortcut methods
    private

    def enabled?
      !@disabled
    end

    def client_track(type, properties, validations)
      validation = (validations || []).reject(&:valid).first
      @client.track type: type, properties: properties, validation: validation
    end
  end
end
