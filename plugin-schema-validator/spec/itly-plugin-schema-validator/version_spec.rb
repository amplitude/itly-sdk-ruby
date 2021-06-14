# frozen_string_literal: true

describe Itly::Plugin::SchemaValidator do
  it do
    expect(Itly::Plugin::SchemaValidator::VERSION).to match(/^\d+\.\d+\.\d+$/)
  end
end
