# frozen_string_literal: true

# Itly main class
class Itly
  # List of registered plugins classes
  @plugins = []

  class << self
    attr_reader :plugins
  end

  # Manage list of Plugins
  module Plugins
    # List of registered plugins objects
    attr_reader :plugins_instances

    # Instanciate all plugins when creating a new Itly object
    def initialize
      @plugins_instances = []

      # Initialize plugins
      instantiate_plugins
      send_to_plugins :init
    end

    private

    # Initialize all registered plugins
    def instantiate_plugins
      Itly.plugins.each do |plugin|
        plugins_instances << plugin.new
      end
    end

    # Send message to all instanciated plugins
    def send_to_plugins(method, *args)
      plugins_instances.each do |plugin|
        begin
          plugin.send method, *args
        rescue StandardError => e
          logger.error "Itly Error in #{plugin.class.name}. #{e.class.name}: #{e.message}"
        end
      end
    end
  end
end
