# frozen_string_literal: true

if ENV['LOCAL_ITLY_GEM']
  lib = File.expand_path('../../../sdk/lib', File.dirname(__FILE__))
  $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
end

require_relative 'plugin/snowplow/snowplow'
require_relative 'plugin/snowplow/context'
require_relative 'plugin/snowplow/call_options'
require_relative 'plugin/snowplow/options'
require_relative 'plugin/snowplow/version'
