# frozen_string_literal: true

module Itly
  # Parent class for all plugins
  class Plugin
    class << self
      # Called by plugins that need to register themselves with Iteratively
      def register_plugin(plugin)
        Itly::Plugins.plugins << plugin
      end
    end

    # A plugin must ovewrite the #init method
    # Otherwise a NotImplementedError exception would remind the developer
    def init
      raise NotImplementedError
    end
  end
end
