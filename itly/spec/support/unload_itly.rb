# frozen_string_literal: true

# Clean Itly class instance variables after a test

RSpec.configure do |config|
  config.after(:each) do |example|
    if example.metadata[:unload_itly]
      Itly::Plugins.plugins.clear
      Itly::Plugins.plugins_instances.clear

      Itly.instance_variable_set '@is_initialized', false
    end
  end
end
