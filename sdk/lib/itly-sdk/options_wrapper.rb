# frozen_string_literal: true

# Itly main class
class Itly
  # OptionsWrapper class for options.destinations keys
  class OptionsWrapper
    def initialize
      @values = {}
    end

    def clear!
      @values.clear
    end

    def method_missing(method_name, *args, &blk)
      if method_name[-1] == '='
        @values[:"#{method_name[0..-2]}"] = args.first
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
