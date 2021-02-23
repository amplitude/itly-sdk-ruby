# frozen_string_literal: true

require 'logger'

# Itly main class
class Itly
  attr_reader :options

  # Options class for Itly object initialisation
  class Options
    attr_accessor :context, :disabled, :environment, :destinations, :logger

    def initialize
      @context = nil
      @disabled = false
      @environment = :development
      @destinations = nil
      @logger = ::Logger.new $stdout, level: Logger::Severity::ERROR
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
