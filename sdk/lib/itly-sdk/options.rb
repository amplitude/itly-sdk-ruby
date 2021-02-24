# frozen_string_literal: true

require 'logger'

# Itly main class
class Itly
  attr_reader :options

  # Options class for Itly object initialisation
  class Options
    attr_accessor :disabled, :environment, :logger
    attr_reader :context, :destinations

    def initialize
      @context = nil
      @disabled = false
      @environment = :development
      @destinations = Itly::OptionsWrapper.new
      @logger = ::Logger.new $stdout, level: Logger::Severity::ERROR
    end

    def context=(properties)
      @context = Itly::Event.new name: 'context', properties: properties
    end

    def destinations=(properties)
      @destinations.clear!
      properties.each do |key, value|
        @destinations.send :"#{key}=", value
      end
    end
  end

  # Shortcut methods
  private

  def disabled?
    !!options.disabled
  end

  def logger
    options.logger
  end
end
