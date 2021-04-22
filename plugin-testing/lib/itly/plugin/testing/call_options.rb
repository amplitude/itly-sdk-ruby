# frozen_string_literal: true

class Itly
  class Plugin
    class Testing
      ##
      # Testing specific plugin options class
      #
      class CallOptions < Itly::PluginCallOptions
      end

      ##
      # Testing specific plugin options class for calls to +identify+
      #
      class IdentifyOptions < CallOptions
      end

      ##
      # Testing specific plugin options class for calls to +group+
      #
      class GroupOptions < CallOptions
      end

      ##
      # Testing specific plugin options class for calls to +track+
      #
      class TrackOptions < CallOptions
      end

      ##
      # Testing specific plugin options class for calls to +alias+
      #
      class AliasOptions < CallOptions
      end
    end
  end
end
