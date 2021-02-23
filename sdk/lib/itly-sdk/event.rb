# frozen_string_literal: true

# Itly main class
class Itly
  # Event class for plugins data
  class Event
    attr_accessor :name, :properties, :id, :version, :metadata

    def initialize(name:, properties: {}, id: nil, version: nil, metadata: nil)
      @name = name
      @properties = properties
      @id = id
      @version = version
      @metadata = metadata
    end
  end
end
