# frozen_string_literal: true

# You can only run rspec from the root directory of the gem, with the following command:
#
#     bin/rspec
#
# If you are working with a local version of Itly sdk, you need to use the following command:
#
#     LOCAL_ITLY_GEM=true bin/rspec
#
raise 'You need to run spec with "bin/rspec"' unless ENV['RSPEC_RUN_FROM_SCRIPT']

# Load files
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'itly/plugin-segment'

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

  # Run specs in random order
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  Kernel.srand config.seed
end

# Do not truncate output
RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length = nil
