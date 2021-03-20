# frozen_string_literal: true

##
# Collection of options for Itly
#
class ItlyOptions
  attr_accessor :environment, :disabled, :plugins, :validation, :logger

  ##
  # @param [Symbol] environment: A Symbol specifying the environment the Itly SDK is running in.
  #   Can be +Itly::Options::Environment::DEVELOPMENT+ or +Itly::Options::Environment::PRODUCTION+
  #   Defaults to +DEVELOPMENT+.
  #
  # @param [TrueClass/FalseClase] disabled: A True/False specifying whether the Itly SDK does any work.
  #   Defaults to false.
  #
  # @param [Array] plugins: Specifies any analytics provider-specific configuration.
  #
  # @param [Symbol] validation: Configures the Itly SDK's behavior when events or traits fail validation.
  #   Value can be one of the following:
  #   - +Itly::Options::Validation::DISABLED+: Disables validation altogether.
  #   - +Itly::Options::Validation::TRACK_INVALID+: Specifies whether events that failed validation
  #     should still be tracked. Defaults to false in development, true in production.
  #   - +Itly::Options::Validation::ERROR_ON_INVALID+: Specifies whether the SDK should throw
  #      an exception when validation fails. Defaults to true in development, false in production.
  #
  #   Defaults to +ERROR_ON_INVALID+ if the environment is set to +DEVELOPMENT+, or +TRACK_INVALID+
  #   if the environment is set to +PRODUCTION+.
  #
  # @param [Logger] logger: Allow to set a custom Logger. Must be a object of the Logger class or child class.
  #   Deflault output to STDOUT and level to ERROR
  #
  def initialize(environment:, disabled:, plugins:, validation:, logger:)
    @environment = environment
    @disabled = disabled
    @plugins = plugins
    @validation = validation
    @logger = logger
  end
end
