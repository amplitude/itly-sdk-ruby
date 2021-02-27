# frozen_string_literal: true

# Itly main class
class Itly
  # Parent class for all plugins
  class Plugin
    class << self
      # Called by plugins that need to register themselves with Iteratively
      def register_plugin(plugin)
        Itly.registered_plugins << plugin
      end
    end

    # A plugin must ovewrite the #load method
    # Otherwise a NotImplementedError exception would remind the developer
    # The param `options` contains the all the options passed to Itly#Init
    # Call #get_plugin_options to get plugin specific options as a Hash
    def load(options:)
      raise NotImplementedError
    end

    def identify(user_id:, properties:); end

    def post_identify(user_id:, properties:, validation_results:); end

    def group(user_id:, group_id:, properties:); end

    def post_group(user_id:, group_id:, properties:, validation_results:); end

    def track(user_id:, event:); end

    def post_track(user_id:, event:, validation_results:); end

    def alias(user_id:, previous_id:); end

    def post_alias(user_id:, previous_id:); end

    def flush; end

    def reset; end

    # A plug-in can return a ValidationResponse object
    def validate(event:); end

    private

    def get_plugin_options(options)
      name = self.class.name.gsub(/([A-Z]+)/, '_\1').gsub(/^_/, '')
      options.destinations.send name.downcase.to_sym
    rescue NoMethodError
      {}
    end
  end
end
