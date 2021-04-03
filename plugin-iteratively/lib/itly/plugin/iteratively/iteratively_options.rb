# frozen_string_literal: true

require 'itly-sdk'

class Itly
  class Plugin
    ##
    # Options for the Iteratively plugin class
    #
    class IterativelyOptions
      attr_reader :url, :disabled, :flush_queue_size, :batch_size, :flush_interval_ms, :max_retries,
        :retry_delay_min, :retry_delay_max, :omit_values

      ##
      # Instantiate a new IterativelyOptions
      #
      # @param [String] url: specify the url to push events to
      # @param [TrueClass/FalseClass] disabled: set to true to disable the Iteratively plugin.
      #   Default to +true+ in production environment, to +false+ otherwise
      # @param [Integer] flush_queue_size (optional): Number of event in the buffer before
      #   a flush is triggered. Default: 10
      # @param [Integer] batch_size (optional): Maximum number of events to send to the server at once. Default: 100
      # @param [Integer] batflush_interval_msch_size (optional): Delay in milisecond between each automatic
      #   flush. Default: 10_000
      # @param [Integer] max_retries (optional): Number of retries for pushing
      #   events to the server. Default: 25
      # @param [Float] retry_delay_min: Minimum delay between retries in seconds. Default: 10.0
      # @param [Float] retry_delay_max: Maximum delay between retries in seconds. Default: 3600.0 (1 hour)
      # @param [TrueClass/FalseClass] omit_values: set to true to send emty data. Default to false
      #
      # rubocop:disable Metrics/ParameterLists
      def initialize(
        url:, disabled: nil, flush_queue_size: 10, batch_size: 100, flush_interval_ms: 10_000, max_retries: 25,
        retry_delay_min: 10.0, retry_delay_max: 3600.0, omit_values: false
      )
        super()
        @url = url
        @disabled = disabled
        @flush_queue_size = flush_queue_size
        @batch_size = batch_size
        @flush_interval_ms = flush_interval_ms
        @max_retries = max_retries
        @retry_delay_min = retry_delay_min
        @retry_delay_max = retry_delay_max
        @omit_values = omit_values
      end
      # rubocop:enable Metrics/ParameterLists
    end
  end
end