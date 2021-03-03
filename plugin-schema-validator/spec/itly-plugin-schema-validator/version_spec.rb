# frozen_string_literal: true

describe Itly::PluginSchemaValidator do
  it do
    expect(Itly::PluginSchemaValidator::VERSION).to match(/^\d+\.\d+\.\d+$/)
  end
end
