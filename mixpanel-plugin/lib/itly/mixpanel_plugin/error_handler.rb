# frozen_string_literal: true

require 'itly-sdk'
require 'mixpanel-ruby'

class Itly
  class MixpanelPlugin < Plugin
    ##
    # Error handler class used by Mixpanel::Tracker
    #
    # Raise an +Itly::RemoteError+ error in case of error
    #
    class ErrorHandler < Mixpanel::ErrorHandler
      def handle(error)
        raise Itly::RemoteError, "The client returned an error: #{error}"
      end
    end
  end
end
