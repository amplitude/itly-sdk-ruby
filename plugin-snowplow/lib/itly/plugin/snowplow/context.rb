# frozen_string_literal: true

class Itly
  class Plugin
    class Snowplow
      ##
      # Snowplow context to be used by CallOptions
      #
      class Context
        attr_reader :schema, :data

        def initialize(schema:, data:)
          @schema = schema
          @data = data
        end

        def to_self_describing_json
          SnowplowTracker::SelfDescribingJson.new schema, data
        end

        def to_s
          "#<Snowplow::Context schema: #{schema} data: #{data}>"
        end
      end
    end
  end
end
