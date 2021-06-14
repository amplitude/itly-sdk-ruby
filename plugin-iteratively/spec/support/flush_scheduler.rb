# frozen_string_literal: true

# Disable the call to Client#start_scheduler so that the scheduler is never started
#
# To bypass: add :allow_scheduler metadata in the `it` or `describe` block
#   - describe 'my test', :allow_scheduler do ...

RSpec.configure do |config|
  config.before(:each) do |example|
    unless example.metadata[:allow_scheduler]
      allow_any_instance_of(Itly::Plugin::Iteratively::Client).to receive(:start_scheduler)
    end
  end
end
