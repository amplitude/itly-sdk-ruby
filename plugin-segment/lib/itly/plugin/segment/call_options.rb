# frozen_string_literal: true

class Itly
  class Plugin
    class Segment
      ##
      # Segment specific plugin options class
      #
      class CallOptions < Itly::PluginCallOptions
        attr_reader :integrations, :callback

        def initialize(integrations: nil, callback: nil)
          @integrations = integrations
          @callback = callback
        end

        def to_s
          class_name = self.class.name.split('::').last
          "#<Segment::#{class_name} integrations: #{integrations} callback: #{callback.nil? ? 'nil' : 'provided'}>"
        end
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
