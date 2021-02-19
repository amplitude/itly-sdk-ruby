# frozen_string_literal: true

# Itly top module
module Itly
  include Itly::Plugins

  # Flag to indicate if the module is already loaded
  @is_initialized = false

  class << self
    attr_reader :is_initialized

    def load
      # Ensure #load was not already called
      raise InitializationError, 'Itly is already initialized.' if is_initialized

      # Initialize plugins
      instantiate_plugins
      send_to_plugins :init

      # Flag as initialized
      @is_initialized = true
    end
  end
end
