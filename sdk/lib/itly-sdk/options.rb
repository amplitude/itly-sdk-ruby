# frozen_string_literal: true

require 'logger'

# Itly main class
class Itly
  attr_reader :options

  def initialize
    super

    @options = Itly::Options.new
    yield @options if block_given?
  end

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
end
