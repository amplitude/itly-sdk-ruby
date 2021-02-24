# frozen_string_literal: true

class Itly
  class ValidationResponse
    attr_accessor :valid, :plugin_id, :message

    def initialize(valid:, plugin_id:, message:)
      @valid = valid
      @plugin_id = plugin_id
      @message = message
    end
  end
end
