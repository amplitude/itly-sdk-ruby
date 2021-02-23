# frozen_string_literal: true

module RspecOptionsDefaultValues
  # rubocop:disable Metrics/AbcSize
  def expect_options_default_values(options)
    expect(options.context).to be(nil)
    expect(options.disabled).to be(false)
    expect(options.environment).to eq(:development)
    expect(options.destinations).to be(nil)
    expect(options.logger).to be_a_kind_of(::Logger)
  end
  # rubocop:enable Metrics/AbcSize
end
