# frozen_string_literal: true

RSpec.configure do |config|
  # Clean Itly class instance variables after a test
  config.after(:each) do |example|
    Itly.plugins.clear if example.metadata[:unload_itly]
  end
end

module RspecItlyHelpers
  def create_itly_object(options = {})
    let(:itly) { Itly.new }
    before do
      itly.load do |o|
        options.each do |key, value|
          o.send :"#{key}=", value
        end
      end
    end
  end
end
