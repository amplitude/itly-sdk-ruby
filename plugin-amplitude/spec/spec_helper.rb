# frozen_string_literal: true

# Load files
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'itly/plugin_amplitude'

# Auto-requiring all files in the support directories
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Enable warnings
  config.warnings = true

  # Print the 3 slowest examples
  config.profile_examples = 3

  # Run specs in random order
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  Kernel.srand config.seed
end
