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
        attr_reader :contexts, :callback

        def initialize(contexts: nil, callback: nil)
          @contexts = contexts
          @callback = callback
        end

        def to_s
          class_name = self.class.name.split('::').last
          contexts_str = contexts.collect(&:to_s).join ', '
          "#<Snowplow::#{class_name} contexts: [#{contexts_str}] callback: #{callback.nil? ? 'nil' : 'provided'}>"
        end
      end
    end
  end
end
