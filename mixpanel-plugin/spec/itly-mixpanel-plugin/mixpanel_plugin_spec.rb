# frozen_string_literal: true

describe Itly::MixpanelPlugin do
  it 'register itself' do
    expect(Itly.registered_plugins).to eq([Itly::MixpanelPlugin])
  end

end
