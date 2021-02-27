# frozen_string_literal: true

class Itly
  ##
  # Contains the result of a validation
  #
  # +valid+: [True/False] indicating if the validation succeeded or failed
  # +plugin_id+: [String] an id identifying your plugin
  # +message+: [String] the message you want to appear in the logs in case of error
  #
  class ValidationResponse
    attr_accessor :valid, :plugin_id, :message

    ##
    # Create a nnew ValidationResponse object
    #
    def initialize(valid:, plugin_id:, message:)
      @valid = valid
      @plugin_id = plugin_id
      @message = message
    end

    ##
    # Describe the object
    #
    # @return [String] the object description
    #
    def to_s
      "#<#{self.class.name}: valid: #{valid}, plugin_id: #{plugin_id}, message: #{message}>"
    end
  end
end
