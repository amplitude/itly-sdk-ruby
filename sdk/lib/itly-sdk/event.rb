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

    def to_s
      "<name: #{name}, properties: #{properties}>"
    end

    def ==(o)
      o.class == self.class && [name, properties, id, version, metadata] ==
        [o.name, o.properties, o.id, o.version, o.metadata]
    end
  end
end
