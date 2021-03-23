# frozen_string_literal: true

# Itly main class
class Itly
  ##
  # PluginOptions class for Itly Plugins #load methods
  #
  # +environment+: A Symbol specifying the environment the Itly SDK is running in.  #
  # +logger+: Allow to set a custom Logger.
  #
  class PluginOptions
    attr_reader :environment, :logger

    ##
    # Create a new PluginOptions object
    #
    def initialize(environment:, logger:)
      @environment = environment
      @logger = logger
    end
  end
end
