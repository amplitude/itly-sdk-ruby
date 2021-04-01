# frozen_string_literal: true

class Itly
  ##
  # Loggers class, provide default usual loggers for convenience
  #
  class Loggers
    def self.itly_dot_log
      Logger.new 'itly.log'
    end

    def self.std_out
      Logger.new $stdout
    end

    def self.nil_logger
      nil
    end
  end
end
