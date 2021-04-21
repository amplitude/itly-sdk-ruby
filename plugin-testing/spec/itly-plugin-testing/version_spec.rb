# frozen_string_literal: true

describe Itly::Plugin::Testing do
  it do
    expect(Itly::Plugin::Testing::VERSION).to match(/^\d+\.\d+\.\d+$/)
  end
end
