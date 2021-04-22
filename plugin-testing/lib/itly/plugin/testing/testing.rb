# frozen_string_literal: true

require 'concurrent'
require 'itly-sdk'

class Itly
  class Plugin
    ##
    # Testing plugin class for Itly SDK
    #
    class Testing < Plugin
      attr_reader :logger, :disabled

      ##
      # Instantiate a new Plugin::Testing
      #
      # @param [TrueClass/FalseClass] disabled: set to true to disable the plugin. Default to false
      #
      def initialize(disabled: false)
        super()
        @calls = Concurrent::Hash.new
        @disabled = disabled
      end

      ##
      # Initialize TestingApi client
      #
      # @param [Itly::PluginOptions] options: plugins options
      #
      def load(options:)
        super
        # Get options
        @logger = options.logger

        # Log
        logger&.info "#{id}: load()"

        logger&.info "#{id}: plugin is disabled!" if @disabled
      end

      ##
      # Empty the cache
      #
      def reset
        @calls.clear
      end

      ##
      # Get all events that was sent to the +track+ method
      #
      # @param [String] user_id: (optional) filter the events returned by the method by the user_id.
      #   Leave it +nil+ to get all events
      # @return [Array] array of EvItly::Eventent objects that was sent to the +track+ method
      #
      def all(user_id: nil)
        calls = @calls['track'].dup
        calls = calls.select { |call| call[:user_id] == user_id } unless user_id.nil?
        calls.collect { |call| call[:event] }
      end

      ##
      # Get events that was sent to the +track+ method of the specified class name
      #
      # @param [Event] class_name: the method return only events of the specified class name
      # @param [String] user_id: (optional) filter the events returned by the method by the user_id.
      #   Leave it +nil+ to get all events
      # @return [Array] array of Itly::Event objects that was sent to the +track+ method
      #
      def of_type(class_name:, user_id: nil)
        calls = all user_id: user_id
        calls.select { |call| call.is_a? class_name }
      end

      ##
      # Get the first event that was sent to the +track+ method of the specified class name
      #
      # @param [Event] class_name: the method return only an event of the specified class name
      # @param [String] user_id: (optional) filter the events returned by the method by the user_id.
      #   Leave it +nil+ to get all events
      # @return [Itly::Event] object that was sent to the +track+ method. +nil+ if none was found
      #
      def first_of_type(class_name:, user_id: nil)
        of_type(class_name: class_name, user_id: user_id).first
      end

      ##
      # Tracking methods
      #
      # Accept any params, store them in the @calls instance variable
      #
      %i[alias identify group track].each do |method_name|
        define_method method_name do |args|
          track_calls method_name.to_s, args
        end
      end

      private

      def enabled?
        !@disabled
      end

      def track_calls(method_name, args)
        @calls[method_name] ||= []
        @calls[method_name] << args
      end
    end
  end
end
