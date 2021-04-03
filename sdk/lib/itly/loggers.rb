# frozen_string_literal: true

class Itly
  ##
  # Loggers class, provide default usual loggers for convenience
  #
  class Loggers
    ##
    # Logger to log into 'itly.log' file on the current directory
    #
    # @return [Logger] the logger
    #
    def self.itly_dot_log
      Logger.new 'itly.log'
    end

    ##
    # Logger to log to standard out
    #
    # @return [Logger] the logger
    #
    def self.std_out
      Logger.new $stdout
    end

    ##
    # No logger
    #
    # @return [NilClass] nothing
    #
    def self.nil_logger
      nil
    end
  end
end
