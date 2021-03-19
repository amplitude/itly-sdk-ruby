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
        attr_reader :api_key, :url, :logger, :buffer_size, :max_retries, :retry_delay_min, :retry_delay_max,
          :omit_values

        # rubocop:disable Metrics/ParameterLists
        def initialize(
            url:, api_key:, logger:, buffer_size:, max_retries:, retry_delay_min:, retry_delay_max:, omit_values:
          )
          @buffer = ::Concurrent::Array.new
          @runner = nil

          @api_key = api_key
          @url = url
          @logger = logger
          @buffer_size = buffer_size
          @max_retries = max_retries
          @retry_delay_min = retry_delay_min
          @retry_delay_max = retry_delay_max
          @omit_values = omit_values
        end
        # rubocop:enable Metrics/ParameterLists

        def track(type:, event:, validation:)
          @buffer << ::Itly::Plugin::Iteratively::Model.new(
            omit_values: omit_values, type: type, event: event, validation: validation
          )

          flush if buffer_full?
        end

        def flush
          # Case: the runner is on, cannot call flush again
          return unless runner_complete?

          # Exit if there is nothing to do
          return if @buffer.empty?

          # Extract the current content of the buffer for processing
          processing = @buffer.shift @buffer.length

          # Run in the background
          @runner = Concurrent::Future.new do
            # Itinialization before the loop starts
            tries = 0

            loop do
              # Case: done with all events in the processing queue
              break if processing.empty?

              # Count the number of tries
              tries += 1
              # Case: successfully sent
              if post_model processing[0]
                # Remove the event from the queue, and reset the number of tries
                processing.shift
                tries = 0

              # Case: could not sent and reached maximum number of allowed tries
              elsif tries >= @max_retries
                # Log
                logger.error 'Iteratively::Client: flush() reached maximun number of tries. '\
                  "#{processing.count} event won't be sent to the server"

                # Discard the list of event in the processing queue
                break

              # Case: could not sent and wait before retrying
              else
                sleep delay_before_next_try(tries)
              end
            end
          end

          @runner.execute
        end

        def shutdown
          @max_retries = 0
          flush
          @runner&.wait_or_cancel @retry_delay_min
        end

        private

        def buffer_full?
          @buffer.length >= @buffer_size
        end

        def post_model(model)
          headers = {
            'Content-Type' => 'application/json',
            'authorization' => "Bearer #{@api_key}"
          }

          resp = Faraday.post(@url, model.to_json, headers)

          # Case: HTTP response 2xx is a Success
          return true if resp.status / 100 == 2

          # Case: HTTP response is 3xx or 4xx or 5xx is an error
          logger.error "Iteratively::Client: post_model() unexpected response. Url: #{url} "\
            "Data: #{model.to_json} Response status: #{resp.status} Response headers: #{resp.response_headers} "\
            "Response body: #{resp.response_body}"
          false
        rescue StandardError => e
          logger.error "Iteratively::Client: post_model() exception #{e.class.name}: #{e.message}"
          false
        end

        def runner_complete?
          @runner.nil? || @runner.complete?
        end

        def delay_before_next_try(nbr_tries)
          percent = (nbr_tries - 1).to_f / (@max_retries - 1)
          rad = percent * Math::PI / 2
          delta = (Math.cos(rad) - 1).abs

          retry_delay_min + delta * (@retry_delay_max - @retry_delay_min)
        end
      end
    end
  end
end
