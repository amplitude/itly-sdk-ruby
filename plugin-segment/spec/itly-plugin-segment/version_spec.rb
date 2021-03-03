# frozen_string_literal: true

describe Itly::PluginSegment do
  it do
    expect(Itly::PluginSegment::VERSION).to match(/^\d+\.\d+\.\d+$/)
  end
end
