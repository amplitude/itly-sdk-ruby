# frozen_string_literal: true

module RspecOptionsDefaultValues
  def expect_options_default_values(options)
    expect(options.instance_variable_get('@default_environment')).to be(true)

    expect(options.disabled).to be(false)
    expect(options.environment).to eq(Itly::Options::Environment::DEVELOPMENT)
    expect(options.instance_variable_get('@validation')).to eq(Itly::Options::Validation::DEFAULT)
    expect(options.validation).to eq(Itly::Options::Validation::ERROR_ON_INVALID)
    expect(options.plugins).to eq([])
    expect(options.logger).to be(nil)
  end
end
