# frozen_string_literal: true

# Itly main class
class Itly
  ##
  # Parent class for all plugins
  #
  # When creating a custom plugin, you need to create a child class of Itly::Plugin
  #
  class Plugin
    ##
    # Called when the Itly SDK is being loaded and is ready to load your plugin.
    #
    # @param [Itly::PluginOptions] options: The option for the plugin
    #
    def load(options:); end

    ##
    # Identify a user in your application and associate all future events with
    # their identity, or to set their traits.
    #
    # @param [String] user_id: the id of the user in your application
    # @param [Hash] properties: the properties containing user's traits to pass to your application
    #
    def identify(user_id:, properties:); end

    def post_identify(user_id:, properties:, validation_results:); end

    ##
    # Associate a user with their group (for example, their department or company),
    # or to set the group's traits.
    #
    # @param [String] user_id: the id of the user in your application
    # @param [String] group_id: the id of the group in your application
    # @param [Hash] properties: the properties to pass to your application
    #
    def group(user_id:, group_id:, properties:); end

    def post_group(user_id:, group_id:, properties:, validation_results:); end

    ##
    # Track an event, call the event's corresponding function.
    #
    # See +Itly#track+ for more information
    #
    # @param [String] user_id: the id of the user in your application
    # @param [Event] event: the events to track
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
    # Force flushing data
    #
    def shutdown; end

    ##
    # Reset the SDK's (and all plugins') state. This method is usually called when a user logs out.
    #
    def reset; end

    ##
    # Validate an Event
    #
    # See +Itly#validate+ for more information
    #
    # Your plugin can return a +Itly::ValidationResponse+ object to provide success status
    # and validation message; otherwise it can return +nil+
    #
    def validate(event:); end

    ##
    # Get the plugin ID, which is the underscored class name. Use only the child class in case of nested classes
    #
    # @return [String] plugin id
    #
    def id
      name = (self.class.name || 'UnknownPluginClass').gsub('::', '-')
      name = (name || 'UnknownPluginClass').gsub(/([A-Z]+)/, '_\1').gsub(/-_/, '-').sub(/^_/, '').sub(/^itly-/i, '')
      name.downcase
    end
  end
end
