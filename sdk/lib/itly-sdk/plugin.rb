# frozen_string_literal: true

# Itly main class
class Itly
  # Parent class for all plugins
  class Plugin
    class << self
      # Called by plugins that need to register themselves with Iteratively
      def register_plugin(plugin)
        Itly.plugins << plugin
      end
    end

    # A plugin must ovewrite the #init method
    # Otherwise a NotImplementedError exception would remind the developer
    def init(options:)
      raise NotImplementedError
    end

    def alias(user_id:, previous_id:); end

    def post_alias(user_id:, previous_id:); end

    def flush; end

    def reset; end
  end
end
