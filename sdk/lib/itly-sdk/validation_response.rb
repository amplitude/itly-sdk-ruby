# frozen_string_literal: true

class Itly
  class ValidationResponse
    attr_accessor :valid
    attr_accessor :plugin_id
    attr_accessor :message

    def initialize(valid:, plugin_id:, message:)
      @valid = valid
      @plugin_id = plugin_id
      @message = message
    end
  end
end