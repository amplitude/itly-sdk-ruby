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
  # +plugins+: Pass the list of Plugins object that will receive all events to be tracked.
  #
  #   Example:
  #     my_plugin = MyPlugin.new api_key: 'abc123'
  #     itly = Itly.new
  #     itly.load do |options|
  #       options.plugins = [my_plugin]
  #     end
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
  # +logger+: Allow to set a custom Logger. Must be a object of the Logger class or child class.
  #   Deflault output to STDOUT and level to ERROR
  #
  class Options
    attr_accessor :disabled, :logger, :plugins
    attr_reader :environment, :default_environment
    attr_writer :validation

    ##
    # Create a new Options object with default values
    #
    def initialize
      @default_environment = true

      @disabled = false
      @environment = Itly::Options::Environment::DEVELOPMENT
      @validation = Itly::Options::Validation::DEFAULT
      @plugins = []
      @logger = nil
    end

    ##
    # Returns the options that are passed to plugin #load
    #
    # @return [Itly::PluginOptions] plugin options object
    #
    def for_plugin
      ::Itly::PluginOptions.new environment: environment, logger: logger
    end

    ##
    # Assign properties to the +environment+ instance variable
    #
    # @param [TrueClass/FalseClass] value for +environment+
    #
    def environment=(value)
      @default_environment = false
      @environment = value
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
