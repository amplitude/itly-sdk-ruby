# frozen_string_literal: true

class Itly
  class Plugin
    # Mixpanel plugin class for Itly SDK
    class Mixpanel
      ##
      # Mixpanel specific plugin options class
      #
      class CallOptions < Itly::PluginCallOptions
      end

      ##
      # Mixpanel specific plugin options class for calls to plugin methods
      #
      %w[Identify Group Page Track Alias].each do |name|
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
