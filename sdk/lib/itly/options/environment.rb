# frozen_string_literal: true

class Itly
  ##
  # Options class for Itly object initialization
  #
  class Options
    ##
    # This module contains values for the field +environment+ of the +Option+ object
    #
    module Environment
      DEVELOPMENT = :development
      PRODUCTION = :production
    end

    def development?
      @environment == Itly::Options::Environment::DEVELOPMENT
    end

    def production?
      @environment == Itly::Options::Environment::PRODUCTION
    end
  end
end
