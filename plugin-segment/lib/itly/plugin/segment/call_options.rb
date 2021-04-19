# frozen_string_literal: true

class Itly
  class Plugin
    class Segment
      ##
      # Segment specific plugin options class
      #
      class CallOptions < Itly::PluginCallOptions
      end

      ##
      # Segment specific plugin options class for calls to +identify+
      #
      class IdentifyOptions < CallOptions
      end

      ##
      # Segment specific plugin options class for calls to +group+
      #
      class GroupOptions < CallOptions
      end

      ##
      # Segment specific plugin options class for calls to +track+
      #
      class TrackOptions < CallOptions
      end

      ##
      # Segment specific plugin options class for calls to +alias+
      #
      class AliasOptions < CallOptions
      end
    end
  end
end
