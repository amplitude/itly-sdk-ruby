# frozen_string_literal: true

# Itly main class
class Itly
  # #
  # Dictionary class for options.plugins values
  #
  class OptionsWrapper
    ##
    # Create a new OptionsWrapper object
    #
    def initialize
      @values = {}
    end

    ##
    # Empty all values contained by the object
    #
    def clear!
      @values.clear
    end

    ##
    # Access to the values through methods
    #
    def method_missing(method_name, *args, &blk)
      # Case: the method name ends with the sign "="
      if method_name[-1] == '='
        @values[:"#{method_name[0..-2]}"] = args.first
      # Case: the method name corresponds to a key of the @values hash
      elsif @values.key?(method_name)
        @values[method_name]
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name[-1] == '=' || @values.key?(method_name) || super
    end
  end
end
