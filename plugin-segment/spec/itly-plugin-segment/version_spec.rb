# frozen_string_literal: true

describe Itly::Plugin::Segment do
  it do
    expect(Itly::Plugin::Segment::VERSION).to match(/^\d+\.\d+\.\d+$/)
  end
end
