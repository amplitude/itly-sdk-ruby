# frozen_string_literal: true

class Itly
  ##
  # Event object used to communicate data between Itly core SDK and its plugins
  #
  # Properties:
  # +name+: The event's name.
  # +properties+: The event's properties.
  # +id+: The event's unique ID in Iteratively.
  # +version+: The event's version, e.g. 2.0.1.
  # +metadata+: The event's metadata.
  #
  class Event
    attr_reader :name, :properties, :id, :version, :metadata

    ##
    # Create a new Event object
    #
    # @param [String] name: The event's name.
    # @param [Hash] properties: The event's properties.
    # @param [String] id: The event's unique ID in Iteratively.
    # @param [String] version: The event's version, e.g. 2.0.1.
    # @param [Hash] metadata: The event's metadata.
    #
    def initialize(name:, properties: {}, id: nil, version: nil, metadata: nil)
      @name = name
      @properties = properties
      @id = id
      @version = version
      @metadata = metadata
    end

    ##
    # Describe the object
    #
    # @return [String] the object description
    #
    def to_s
      "#<#{self.class.name}: name: #{name}, properties: #{properties}>"
    end

    ##
    # Compare the object to another
    #
    # @param [Object] other: the object to compare to
    #
    # @return [True/False] are the objects similar
    #
    def ==(other)
      other.class == self.class && [name, properties, id, version, metadata] ==
        [other.name, other.properties, other.id, other.version, other.metadata]
    end
  end
end
