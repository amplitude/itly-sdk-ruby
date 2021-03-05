# frozen_string_literal: true

describe Itly::PluginIteratively do
  it 'register itself' do
    expect(Itly.registered_plugins).to eq([Itly::PluginIteratively])
  end

end
