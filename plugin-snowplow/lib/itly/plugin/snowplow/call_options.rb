# frozen_string_literal: true

class Itly
  class Plugin
    class Snowplow
      ##
      # Snowplow specific plugin options class
      #
      class CallOptions < Itly::PluginCallOptions
      end

      ##
      # Snowplow specific plugin options class for calls to +identify+
      #
      class IdentifyOptions < CallOptions
      end

      ##
      # Snowplow specific plugin options class for calls to +track+
      #
      class TrackOptions < CallOptions
      end
    end
  end
end
