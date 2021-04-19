# frozen_string_literal: true

class Itly
  class Plugin
    class Amplitude
      ##
      # Amplitude specific plugin options class
      #
      class CallOptions < Itly::PluginCallOptions
        attr_reader :callback

        def initialize(callback: nil)
          @callback = callback
        end

        def to_s
          class_name = self.class.name.split('::').last
          "#<Amplitude::#{class_name} callback: #{callback.nil? ? 'nil' : 'provided'}>"
        end
      end

      ##
      # Amplitude specific plugin options class for calls to +identify+
      #
      class IdentifyOptions < CallOptions
      end

      ##
      # Amplitude specific plugin options class for calls to +track+
      #
      class TrackOptions < CallOptions
      end
    end
  end
end
