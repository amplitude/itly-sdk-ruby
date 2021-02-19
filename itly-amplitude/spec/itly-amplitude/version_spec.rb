# frozen_string_literal: true

describe Itly::Amplitude do
  it do
    expect(Itly::Amplitude::VERSION).to match(/^\d+\.\d+\.\d+$/)
  end
end
