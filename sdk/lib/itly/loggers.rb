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

    ##
    # Shorthand to filter variables in a log message
    #
    # Check if the variable has a value, and return a list for the log message
    #
    # @param [Hash] vars: list of variables
    # @return [String] log message
    #
    def self.vars_to_log(vars)
      vars.collect do |name, value|
        next if value.nil?

        if value.is_a?(Hash) || value.is_a?(Array)
          "#{name}: #{value}" if value.any?
        else
          "#{name}: #{value}"
        end
      end.compact.join ', '
    end
  end
end
