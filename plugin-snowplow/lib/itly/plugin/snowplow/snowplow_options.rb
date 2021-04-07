# frozen_string_literal: true

require 'itly-sdk'

class Itly
  class Plugin
    ##
    # Snowplow plugin class for Itly SDK
    #
    class SnowplowOptions
      attr_reader :endpoint, :vendor, :protocol, :method, :buffer_size, :disabled

      ##
      # Instantiate a new SnowplowOptions
      #
      # @param [String] endpoint: specify the Snowplow endpoint
      # @param [String] vendor: specify the Snowplow vendor
      # @param [String] protocol: specify the protocol to connect to the Snowplow endpoint.
      #   Can be 'http' or 'https'. Default to 'http'
      # @param [String] method: specify the HTTP verb to use when sending events to the Snowplow endpoint.
      #   Can be 'get' or 'post'. Default to 'get'
      # @param [Integer] buffer_size: specify the buffer size before flushing event to the Snowplow endpoint.
      #   Leave it to +nil+ to set it's default value. Default to 1 for GET method, and 10 for POST
      # @param [TrueClass/FalseClass] disabled: set to true to disable the plugin. Default to false
      #
      def initialize(endpoint:, vendor:, protocol: 'http', method: 'get', buffer_size: nil, disabled: false)
        super()
        @endpoint = endpoint
        @vendor = vendor
        @protocol = protocol
        @method = method
        @buffer_size = buffer_size
        @disabled = disabled
      end
    end
  end
end
