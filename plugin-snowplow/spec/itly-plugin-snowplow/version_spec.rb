# frozen_string_literal: true

describe Itly::Plugin::Snowplow do
  it do
    expect(Itly::Plugin::Snowplow::VERSION).to match(/^\d+\.\d+\.\d+$/)
  end
end
