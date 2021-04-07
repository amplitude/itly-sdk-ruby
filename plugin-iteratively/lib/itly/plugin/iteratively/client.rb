# frozen_string_literal: true

require 'concurrent'
require 'faraday'
require 'itly-sdk'

class Itly
  class Plugin
    class Iteratively
      ##
      # HTTP client for the plugin requests
      #
      class Client
        attr_reader :api_key, :url, :logger, :flush_queue_size, :batch_size, :flush_interval_ms, :max_retries,
          :retry_delay_min, :retry_delay_max, :omit_values

        # rubocop:disable Metrics/ParameterLists
        def initialize(
          url:, api_key:, logger:, flush_queue_size:, batch_size:, flush_interval_ms:, max_retries:,
          retry_delay_min:, retry_delay_max:, omit_values:
        )
          @buffer = ::Concurrent::Array.new
          @runner = @scheduler = nil

          @api_key = api_key
          @url = url
          @logger = logger
          @flush_queue_size = flush_queue_size
          @batch_size = batch_size
          @flush_interval_ms = flush_interval_ms
          @max_retries = max_retries
          @retry_delay_min = retry_delay_min
          @retry_delay_max = retry_delay_max
          @omit_values = omit_values

          # Start the scheduler
          start_scheduler
        end
        # rubocop:enable Metrics/ParameterLists

        def track(type:, event:, properties:, validation:)
          @buffer << ::Itly::Plugin::Iteratively::TrackModel.new(
            omit_values: omit_values, type: type, event: event, properties: properties, validation: validation
          )

          flush if buffer_full?
        end

        def flush
          # Case: the runner is on, cannot call flush again
          return unless runner_complete?

          # Exit if there is nothing to do
          return if @buffer.empty?

          # Extract the current content of the buffer for processing
          processing = @buffer.each_slice(@batch_size).to_a
          @buffer.clear

          # Run in the background
          @runner = Concurrent::Future.new do
            processing.each do |batch|
              # Itinialization before the loop starts
              tries = 0

              loop do
                # Count the number of tries
                tries += 1

                # Case: successfully sent
                break if post_models batch

                # Case: could not sent and reached maximum number of allowed tries
                if tries >= @max_retries
                  # Log
                  logger&.error 'Iteratively::Client: flush() reached maximun number of tries. '\
                    "#{batch.count} events won't be sent to the server"

                  # Discard the list of event in the batch queue
                  break

                # Case: could not sent and wait before retrying
                else
                  sleep delay_before_next_try(tries)
                end
              end
            end
          end

          @runner.execute
        end

        def shutdown(force: false)
          @scheduler&.cancel

          if force
            @runner&.cancel
            return
          end

          @max_retries = 0
          flush
          @runner&.wait_or_cancel @retry_delay_min
        end

        private

        def buffer_full?
          @buffer.length >= @flush_queue_size
        end

        def post_models(models)
          data = {
            objects: models
          }.to_json
          headers = {
            'Content-Type' => 'application/json',
            'authorization' => "Bearer #{@api_key}"
          }
          resp = Faraday.post(@url, data, headers)

          # Case: HTTP response 2xx is a Success
          return true if (200...300).include? resp.status

          # Case: Error
          logger&.error "Iteratively::Client: post_models() unexpected response. Url: #{url} "\
            "Data: #{data} Response status: #{resp.status} Response headers: #{resp.headers} "\
            "Response body: #{resp.body}"
          false
        rescue StandardError => e
          logger&.error "Iteratively::Client: post_models() exception #{e.class.name}: #{e.message}"
          false
        end

        def runner_complete?
          @runner.nil? || @runner.complete?
        end

        # Generates progressively increasing values to wait between client calls
        # For max_retries: 25, retry_delay_min: 10.0, retry_delay_max: 3600.0, generated values are:
        # 10, 18, 41, 79, 132, 201, 283, 380, 491, 615, 752, 901, 1061, 1233, 1415, 1606,
        # 1805, 2012, 2226, 2446, 2671, 2900, 3131, 3365, 3600
        def delay_before_next_try(nbr_tries)
          percent = (nbr_tries - 1).to_f / (@max_retries - 1)
          rad = percent * Math::PI / 2
          delta = (Math.cos(rad) - 1).abs

          retry_delay_min + delta * (@retry_delay_max - @retry_delay_min)
        end

        def start_scheduler
          @scheduler = Concurrent::ScheduledTask.new(@flush_interval_ms / 1000.0) do
            flush unless runner_complete?
            start_scheduler
          end
          @scheduler.execute
        end
      end
    end
  end
end
