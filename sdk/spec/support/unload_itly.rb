# frozen_string_literal: true

# Clean Itly class instance variables after a test

RSpec.configure do |config|
  config.after(:each) do |example|
    Itly.plugins.clear if example.metadata[:unload_itly]
  end
end
