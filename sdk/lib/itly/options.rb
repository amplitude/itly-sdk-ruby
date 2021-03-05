# frozen_string_literal: true

require 'logger'

# Itly main class
class Itly
  attr_reader :options

  ##
  # Options class for Itly object initialization
  #
  # Properties:
  #
  # +context+: A Hash with a set of properties to add to every event sent by the Itly SDK.
  #   Only available if there is at least one source template associated with your
  #   team's tracking plan.
  #
  # +disabled+: A True/False specifying whether the Itly SDK does any work.
  #   When true, all calls to the Itly SDK will be no-ops. Useful in local or development environments.
  #
  #   Defaults to false.
  #
  # +environment+: A Symbol specifying the environment the Itly SDK is running in.
  #   Can be +Itly::Options::Environment::DEVELOPMENT+ or +Itly::Options::Environment::PRODUCTION+
  #
  #   Environment determines which Access Token is used to load the underlying analytics provider libraries.
  #   The option also determines safe defaults for handling event validation errors. In production,
  #   when the SDK detects an invalid event, it will log an error but still let the event through.
  #   In development, the SDK will throw an exception to alert you that something is wrong.
  #
  #   Defaults to +DEVELOPMENT+.
  #
  # +plugins+: Specifies any analytics provider-specific configuration. The Itly SDK passes these
  #   objects in when loading the underlying analytics provider libraries.
  #
  #   To assign options to a specific plugin, you can assign a hash to the plugin class's
  #   underscored name, exempt from the leading "plugin".
  #   For example, if your plugin class is PluginMyDashboardApp the option key will be
  #   +my_dashboard_app+. You can pass specific options to it like this:
  #
  #       options.plugins.my_dashboard_app = {version: '1.3.7', log: 'verbose'}
  #
  # +validation+: Configures the Itly SDK's behavior when events or traits fail validation against
  #   your tracking plan. Value can be one of the following:
  #   - +Itly::Options::Validation::DISABLED+: Disables validation altogether.
  #   - +Itly::Options::Validation::TRACK_INVALID+: Specifies whether events that failed validation
  #     should still be tracked. Defaults to false in development, true in production.
  #   - +Itly::Options::Validation::ERROR_ON_INVALID+: Specifies whether the SDK should throw
  #      an exception when validation fails. Defaults to true in development, false in production.
  #
  #   Defaults to +ERROR_ON_INVALID+ if the environment is set to +DEVELOPMENT+, or +TRACK_INVALID+
  #   if the environment is set to +PRODUCTION+.
  #
  class Options
    attr_accessor :disabled, :environment, :logger
    attr_reader :context, :plugins
    attr_writer :validation

    ##
    # Create a new Options object with default values
    #
    def initialize
      @context = nil
      @disabled = false
      @environment = Itly::Options::Environment::DEVELOPMENT
      @validation = Itly::Options::Validation::DEFAULT
      @plugins = Itly::OptionsWrapper.new
      @logger = ::Logger.new $stdout, level: Logger::Severity::ERROR
    end

    ##
    # Assign properties to the +context+ instance variable
    #
    # @param [Hash] properties to assign to the "context" Event object
    #
    def context=(properties)
      @context = Itly::Event.new name: 'context', properties: properties
    end

    ##
    # Return the current validation behavior
    #
    # @return [Itly::Options::Validation] validation behavior
    #
    def validation
      if @validation == Itly::Options::Validation::DEFAULT
        if development?
          Itly::Options::Validation::ERROR_ON_INVALID
        else
          Itly::Options::Validation::TRACK_INVALID
        end
      else
        @validation
      end
    end
  end

  # Shortcut methods
  private

  def enabled?
    !options.disabled
  end

  def validation_enabled?
    options.validation != Itly::Options::Validation::DISABLED
  end

  def logger
    options.logger
  end
end
