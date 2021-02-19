# frozen_string_literal: true

module Itly
  # Manage list of Plugins
  module Plugins
    # List of registered plugins classes
    @plugins = []

    # List of registered plugins objects
    @plugins_instances = []

    class << self
      attr_reader :plugins, :plugins_instances
    end

    # Extend base class with module's class methods
    def self.included(base)
      base.extend ClassMethods
    end

    # Methods that extend Itly module
    module ClassMethods
      # Initialize all registered plugins
      def instantiate_plugins
        Itly::Plugins.plugins.each do |plugin|
          Itly::Plugins.plugins_instances << plugin.new
        end
      end

      # Send message to all instanciated plugins
      def send_to_plugins(method, *args)
        Itly::Plugins.plugins_instances.each do |plugin|
          plugin.send method, *args
        end
      end
    end
  end
end
