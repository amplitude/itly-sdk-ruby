# frozen_string_literal: true

require 'itly-sdk'

class Itly
  class Plugin
    ##
    # Snowplow plugin class for Itly SDK
    #
    class SnowplowOptions
      attr_reader :endpoint, :vendor, :disabled

      ##
      # Instantiate a new SnowplowOptions
      #
      # @param [String] endpoint: specify the Snowplow endpoint
      # @param [String] vendor: specify the Snowplow vendor
      # @param [TrueClass/FalseClass] disabled: set to true to disable the plugin. Default to false
      #
      def initialize(endpoint:, vendor:, disabled: false)
        super()
        @endpoint = endpoint
        @vendor = vendor
        @disabled = disabled
      end
    end
  end
end
