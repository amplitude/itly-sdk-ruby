# frozen_string_literal: true

class Itly
  class Plugin
    # Amplitude plugin class for Itly SDK
    class Amplitude
      ##
      # Amplitude specific plugin options class
      #
      class CallOptions < Itly::PluginCallOptions
        PROPS = %w[device_id time groups app_version platform os_name os_version device_brand device_manufacturer
                   device_model carrier country region city dma language price quantity revenue productId revenueType
                   location_lat location_lng ip idfa idfv adid android_id event_id session_id insert_id].freeze

        attr_reader :callback, *PROPS

        class_eval(
          <<-EVAL, __FILE__, __LINE__ + 1
            def initialize(callback: nil, #{PROPS.collect { |p| "#{p}: nil" }.join ', '})  # def initialize(callback: nil, device_id: nil, ...)
              super()                                                                      #   super()
              @callback = callback                                                         #   @callback = callback
              #{PROPS.collect { |p| "@#{p} = #{p}" }.join "\n"}                            #   @device_id = device_id
            end                                                                            # end
          EVAL
        )

        ##
        # Return all properties to be passed to the client
        # While excluding the `callback` property
        #
        # @return [Hash] properties
        #
        def to_hash
          PROPS.each_with_object({}) { |prop, hash| hash[prop.to_sym] = send(prop) unless send(prop).nil? }
        end

        ##
        # Get the plugin description, for logs
        #
        # @return [String] description
        #
        def to_s
          class_name = self.class.name.split('::').last
          props = PROPS.collect { |prop| " #{prop}: #{send prop}" unless send(prop).nil? }.compact
          "#<Amplitude::#{class_name} callback: #{callback.nil? ? 'nil' : 'provided'}#{props.join}>"
        end
      end

      ##
      # Amplitude specific plugin options class for calls to plugin methods
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
