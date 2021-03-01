# frozen_string_literal: true

if ENV['LOCAL_ITLY_GEM']
  lib = File.expand_path('../../../sdk/lib', __dir__)
  $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
end

require_relative 'amplitude_plugin/amplitude_plugin'
require_relative 'amplitude_plugin/version'
