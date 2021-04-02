# frozen_string_literal: true

if ENV['LOCAL_ITLY_GEM']
  lib = File.expand_path('../../../sdk/lib', File.dirname(__FILE__))
  $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
end

require_relative 'plugin/iteratively/iteratively_options'
require_relative 'plugin/iteratively/iteratively'
require_relative 'plugin/iteratively/track_type'
require_relative 'plugin/iteratively/track_model'
require_relative 'plugin/iteratively/client'
require_relative 'plugin/iteratively/version'
