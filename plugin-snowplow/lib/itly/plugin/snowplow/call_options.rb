# frozen_string_literal: true

class Itly
  class Plugin
    # Snowplow plugin class for Itly SDK
    class Snowplow
      ##
      # Snowplow specific plugin options class
      #
      class CallOptions < Itly::PluginCallOptions
      end

      ##
      # Snowplow specific plugin options class for calls to +page+
      #
      class PageOptions < CallOptions
        attr_reader :contexts, :callback

        def initialize(contexts: nil, callback: nil)
          super()
          @contexts = contexts
          @callback = callback
        end

        def to_s
          class_name = self.class.name.split('::').last
          contexts_str = contexts.nil? ? 'nil' : "[#{contexts.collect(&:to_s).join ', '}]"
          "#<Snowplow::#{class_name} contexts: #{contexts_str} callback: #{callback.nil? ? 'nil' : 'provided'}>"
        end
      end

      ##
      # Snowplow specific plugin options class for calls to +track+
      #
      class TrackOptions < CallOptions
        attr_reader :contexts, :callback

        def initialize(contexts: nil, callback: nil)
          super()
          @contexts = contexts
          @callback = callback
        end

        def to_s
          class_name = self.class.name.split('::').last
          contexts_str = contexts.nil? ? 'nil' : "[#{contexts.collect(&:to_s).join ', '}]"
          "#<Snowplow::#{class_name} contexts: #{contexts_str} callback: #{callback.nil? ? 'nil' : 'provided'}>"
        end
      end

      ##
      # Snowplow specific plugin options class for calls to plugin methods
      #
      %w[Identify Group Alias].each do |name|
        class_eval(
          <<-EVAL, __FILE__, __LINE__ + 1
            class #{name}Options < CallOptions         # class IdentifyOptions < CallOptions
            end                                        # end
          EVAL
        )
      end
    end
  end
end
