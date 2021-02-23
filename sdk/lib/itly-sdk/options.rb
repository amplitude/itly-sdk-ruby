# frozen_string_literal: true

require 'logger'

# Itly main class
class Itly
  attr_reader :options

  # Options class for Itly object initialisation
  class Options
    attr_accessor :disabled, :environment, :destinations, :logger
    attr_reader :context

    def initialize
      @context = nil
      @disabled = false
      @environment = :development
      @destinations = nil
      @logger = ::Logger.new $stdout, level: Logger::Severity::ERROR
    end

    def context=(properties)
      @context = Itly::Event.new name: 'context', properties: properties
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
