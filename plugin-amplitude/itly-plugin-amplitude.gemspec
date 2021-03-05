# frozen_string_literal: true

require_relative 'lib/itly/plugin_amplitude'

Gem::Specification.new do |spec|
  spec.name          = 'itly-plugin-amplitude'
  spec.version       = Itly::PluginAmplitude::VERSION
  spec.authors       = ['Benjamin Bouchet']
  spec.email         = ['randoum@gmail.com']

  spec.summary       = 'Amplitude plugin for Iteratively SDK for Ruby'
  spec.description   = 'Track and validate analytics with a unified, extensible interface ' \
                       'that works with all your 3rd party analytics providers.'
  spec.homepage      = 'https://github.com/iterativelyhq/itly-sdk-ruby'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.6.0')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org/'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/iterativelyhq/itly-sdk-ruby/plugin-amplitude'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'amplitude-api', '~> 0.3'
  spec.add_dependency 'rbs', '~> 1.0'
  spec.add_dependency 'steep', '~> 0.41'
  spec.add_development_dependency 'rspec'
end
