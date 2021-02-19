# frozen_string_literal: true

# NOTE: hack to be able to work with itly gem in a local folder
# TODO: remove before publishing to rubygem
lib = File.expand_path('../../itly/lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'itly'

require_relative 'amplitude/version'
