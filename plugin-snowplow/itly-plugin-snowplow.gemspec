# frozen_string_literal: true

require_relative 'lib/itly/plugin/snowplow/version'

Gem::Specification.new do |spec|
  spec.name          = 'itly-plugin-snowplow'
  spec.version       = Itly::Plugin::Snowplow::VERSION
  spec.authors       = ['Benjamin Bouchet']
  spec.email         = ['randoum@gmail.com']

  spec.summary       = 'Snowplow plugin for Iteratively SDK for Ruby'
  spec.description   = 'Track and validate analytics with a unified, extensible interface ' \
                       'that works with all your 3rd party analytics providers.'
  spec.homepage      = 'https://github.com/iterativelyhq/itly-sdk-ruby'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.6.0')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org/'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/iterativelyhq/itly-sdk-ruby/plugin-snowplow'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'itly-sdk', '~> 0.1'
  spec.add_dependency 'snowplow-tracker', '~> 0.6'
end