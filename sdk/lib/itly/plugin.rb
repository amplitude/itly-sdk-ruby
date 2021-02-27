# frozen_string_literal: true

# Itly main class
class Itly
  ##
  # Parent class for all plugins
  #
  # When creating a custom plugin you need to create a child class of Itly::Plugin
  #
  class Plugin
    class << self
      ##
      # Trigger for a plugin to register itslef with Itly, so that it can be instanciated
      #
      def inherited(subclass)
        super
        Itly.registered_plugins.push subclass
      end
    end

    ##
    # Called when the Itly SDK is being loaded and is ready to load your plugin.
    #
    # A plugin must ovewrite the #load method, or a NotImplementedError exception if raised
    #
    # @param [Itly::Options] options: The same configuration object passed to +itly.load+
    #   when the SDK was being initialized.
    #
    #   To retrieve plugin specific options you can call:
    #
    #       get_plugin_options options
    #
    def load(options:)
      raise NotImplementedError
    end

    ##
    # Identify a user in your application and associate all future events with
    # their identity, or to set their traits.
    #
    # See +Itly#identify+ for more information
    #
    def identify(user_id:, properties:); end

    def post_identify(user_id:, properties:, validation_results:); end

    ##
    # Asociate a user with their group (for example, their department or company),
    # or to set the group's traits.
    #
    # See +Itly#group+ for more information
    #
    def group(user_id:, group_id:, properties:); end

    def post_group(user_id:, group_id:, properties:, validation_results:); end

    ##
    # Track an event, call the event's corresponding function. Every event in
    # your tracking plan gets its own function in the Itly SDK.
    #
    # See +Itly#track+ for more information
    #
    def track(user_id:, event:); end

    def post_track(user_id:, event:, validation_results:); end

    ##
    # Associate one user ID with another (typically a known user ID with an anonymous one).
    #
    # See +Itly#alias+ for more information
    #
    def alias(user_id:, previous_id:); end

    def post_alias(user_id:, previous_id:); end

    ##
    # Flush data
    #
    def flush; end

    ##
    # Reset the SDK's (and all plugins') state. This method is usually called when a user logs out.
    #
    def reset; end

    ##
    # Validate an Event
    #
    # See +Itly#validate+ for more information
    #
    # Your plugin can return +Itly::ValidationResponse+ object to provide success status
    # and validation message; otherwire it can return +nil+
    #
    def validate(event:); end

    protected

    ##
    # Get plugin specific options
    #
    # @param [Ilty::Options] options: the options to retrieve from
    #
    # @return [Hash] the plugin specific options
    #
    def get_plugin_options(options)
      # Get the underscored version of the plugin's class name
      name = self.class.name.gsub(/([A-Z]+)/, '_\1').gsub(/^_/, '')
      # Retrieve the options
      options.plugins.send name.downcase.to_sym
    rescue NoMethodError
      # If the underscored class name wans not found in the options, return an empty hash
      {}
    end
  end
end
