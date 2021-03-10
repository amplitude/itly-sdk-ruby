# frozen_string_literal: true

require 'itly-sdk'

class Itly
  class Plugin
    class Iteratively
      ##
      # HTTP client for the plugin requests
      #
      class Client
        attr_reader :api_key, :url

        def initialize(url:, api_key:)
          @url = url
          @api_key = api_key
        end

        def track(type:, properties:, validation:); end
      end
    end
  end
end
