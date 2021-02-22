# frozen_string_literal: true

# Clean Itly class instance variables after a test

RSpec.configure do |config|
  config.after(:each) do |example|
    if example.metadata[:unload_itly]
      Itly.plugins.clear
    end
  end
end
