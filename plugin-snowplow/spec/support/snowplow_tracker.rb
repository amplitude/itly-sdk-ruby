# frozen_string_literal: true

module SnowplowTracker
  class SelfDescribingJson
    def ==(other)
      other.class == self.class && to_json == other.to_json
    end
  end
end
