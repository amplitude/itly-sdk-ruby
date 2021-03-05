# frozen_string_literal: true

if ENV['LOCAL_ITLY_GEM']
  lib = File.expand_path('../../../sdk/lib', File.dirname(__FILE__))
  $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
end

require_relative 'plugin_mixpanel/error_handler'
require_relative 'plugin_mixpanel/plugin_mixpanel'
require_relative 'plugin_mixpanel/version'
