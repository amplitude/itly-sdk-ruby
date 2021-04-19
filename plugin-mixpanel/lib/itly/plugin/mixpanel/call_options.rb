# frozen_string_literal: true

class Itly
  class Plugin
    class Mixpanel
      ##
      # Mixpanel specific plugin options class
      #
      class CallOptions < Itly::PluginCallOptions
      end

      ##
      # Mixpanel specific plugin options class for calls to +identify+
      #
      class IdentifyOptions < CallOptions
      end

      ##
      # Mixpanel specific plugin options class for calls to +track+
      #
      class TrackOptions < CallOptions
      end

      ##
      # Mixpanel specific plugin options class for calls to +alias+
      #
      class AliasOptions < CallOptions
      end
    end
  end
end
