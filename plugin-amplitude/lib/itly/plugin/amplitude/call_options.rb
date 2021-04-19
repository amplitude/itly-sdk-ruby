# frozen_string_literal: true

class Itly
  class Plugin
    class Amplitude
      ##
      # Amplitude specific plugin options class
      #
      # rubocop:disable Lint/EmptyClass
      class CallOptions < Itly::PluginCallOptions
      end
      # rubocop:enable Lint/EmptyClass

      ##
      # Amplitude specific plugin options class for calls to +identify+
      #
      # rubocop:disable Lint/EmptyClass
      class IdentifyOptions < CallOptions
      end
      # rubocop:enable Lint/EmptyClass

      ##
      # Amplitude specific plugin options class for calls to +identify+
      #
      # rubocop:disable Lint/EmptyClass
      class TrackOptions < CallOptions
      end
      # rubocop:enable Lint/EmptyClass
    end
  end
end
