# frozen_string_literal: true

require 'logger'

# Itly main class
class Itly
  attr_reader :options

  # Options class for Itly object initialisation
  class Options
    attr_accessor :disabled, :environment, :logger
    attr_reader :context, :plugins
    attr_writer :validation

    def initialize
      @context = nil
      @disabled = false
      @environment = Itly::Options::Environment::DEVELOPMENT
      @validation = Itly::Options::Validation::DEFAULT
      @plugins = Itly::OptionsWrapper.new
      @logger = ::Logger.new $stdout, level: Logger::Severity::ERROR
    end

    def context=(properties)
      @context = Itly::Event.new name: 'context', properties: properties
    end

    def plugins=(properties)
      @plugins.clear!
      properties.each do |key, value|
        @plugins.send :"#{key}=", value
      end
    end

    def validation
      if @validation == Itly::Options::Validation::DEFAULT
        if @environment == Itly::Options::Environment::DEVELOPMENT
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

  def disabled?
    !!options.disabled
  end

  def validation_disabled?
    options.validation == Itly::Options::Validation::DISABLED
  end

  def logger
    options.logger
  end
end
