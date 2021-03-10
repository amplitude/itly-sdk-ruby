# frozen_string_literal: true

describe Itly::Plugin::Amplitude do
  it do
    expect(Itly::Plugin::Amplitude::VERSION).to match(/^\d+\.\d+\.\d+$/)
  end
end
