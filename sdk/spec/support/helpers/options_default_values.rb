# frozen_string_literal: true

module RspecOptionsDefaultValues
  # rubocop:disable Metrics/AbcSize
  def expect_options_default_values(options)
    expect(options.context).to be(nil)
    expect(options.disabled).to be(false)
    expect(options.environment).to eq(Itly::Options::Environment::DEVELOPMENT)
    expect(options.instance_variable_get('@validation')).to eq(Itly::Options::Validation::DEFAULT)
    expect(options.validation).to eq(Itly::Options::Validation::ERROR_ON_INVALID)
    expect(options.plugins).to be_a_kind_of(Itly::OptionsWrapper)
    expect(options.logger).to be_a_kind_of(::Logger)
  end
  # rubocop:enable Metrics/AbcSize
end
