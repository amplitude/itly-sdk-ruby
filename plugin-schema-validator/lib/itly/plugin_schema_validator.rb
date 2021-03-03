# frozen_string_literal: true

if ENV['LOCAL_ITLY_GEM']
  lib = File.expand_path('../../../sdk/lib', __dir__)
  $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
end

require_relative 'plugin_schema_validator/plugin_schema_validator'
require_relative 'plugin_schema_validator/version'
