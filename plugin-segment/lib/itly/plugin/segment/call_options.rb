# frozen_string_literal: true

class Itly
  class Plugin
    # Segment plugin class for Itly SDK
    class Segment
      ##
      # Segment specific plugin options class
      #
      class CallOptions < Itly::PluginCallOptions
        attr_reader :callback, :integrations, :context, :message_id, :timestamp, :anonymous_id

        def initialize(
          callback: nil, integrations: nil, context: nil, message_id: nil, timestamp: nil, anonymous_id: nil
        )
          super()
          @integrations = integrations
          @callback = callback
          @context = context
          @message_id = message_id
          @timestamp = timestamp
          @anonymous_id = anonymous_id
        end

        ##
        # Return all properties to be passed to the client
        # While excluding the `callback` property
        #
        # @return [Hash] properties
        #
        def to_hash
          %w[integrations context message_id timestamp anonymous_id].each_with_object({}) do |prop, hash|
            hash[prop.to_sym] = send(prop) unless send(prop).nil?
          end
        end

        ##
        # Get the plugin description, for logs
        #
        # @return [String] description
        #
        def to_s
          class_name = self.class.name.split('::').last
          props = %w[integrations context message_id timestamp anonymous_id].collect do |prop|
            " #{prop}: #{send prop}" unless send(prop).nil?
          end.compact
          "#<Segment::#{class_name} callback: #{callback.nil? ? 'nil' : 'provided'}#{props.join}>"
        end
      end

      ##
      # Segment specific plugin options class for calls to plugin methods
      #
      %w[Identify Group Page Track Alias].each do |name|
        class_eval(
          <<-EVAL, __FILE__, __LINE__ + 1
            class #{name}Options < CallOptions         # class IdentifyOptions < CallOptions
            end                                        # end
          EVAL
        )
      end
    end
  end
end
