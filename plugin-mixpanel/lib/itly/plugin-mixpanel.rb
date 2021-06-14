# frozen_string_literal: true

if ENV['LOCAL_ITLY_GEM']
  lib = File.expand_path('../../../sdk/lib', File.dirname(__FILE__))
  $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
end

require_relative 'plugin/mixpanel/mixpanel'
require_relative 'plugin/mixpanel/options'
require_relative 'plugin/mixpanel/call_options'
require_relative 'plugin/mixpanel/error_handler'
require_relative 'plugin/mixpanel/version'
