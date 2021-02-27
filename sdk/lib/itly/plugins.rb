# frozen_string_literal: true

require 'concurrent-ruby'

# Itly main class
class Itly
  # List of registered plugins classes
  @registered_plugins = Concurrent::Array.new

  class << self
    attr_reader :registered_plugins
  end

  ##
  # Manage list of Plugins
  #
  module Plugins
    # List of registered plugins objects
    attr_reader :plugins_instances

    private

    # Initialize all registered plugins
    def instantiate_plugins
      Itly.registered_plugins.each do |plugin|
        plugins_instances << plugin.new
      end
    end

    # Call lambda to all instanciated plugins
    def run_on_plugins(action)
      plugins_instances.collect do |plugin|
        action.call(plugin)
      rescue StandardError => e
        logger.error "Itly Error in #{plugin.class.name}. #{e.class.name}: #{e.message}"
        nil
      end.compact
    end
  end
end
