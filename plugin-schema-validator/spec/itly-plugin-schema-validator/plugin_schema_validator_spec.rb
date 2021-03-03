# frozen_string_literal: true

describe Itly::PluginSchemaValidator do
  it 'register itself' do
    expect(Itly.registered_plugins).to eq([Itly::PluginSchemaValidator])
  end
end
