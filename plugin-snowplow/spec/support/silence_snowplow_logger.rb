# frozen_string_literal: true

# The snowplow tracker logger is too noisy in the specs. This is silencing it

RSpec.configure do |config|
  config.before(:each) do
    stub_const 'SnowplowTracker::LOGGER', Logger.new('/dev/null')
  end
end
