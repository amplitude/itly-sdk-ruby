# frozen_string_literal: true

describe Itly::AmplitudePlugin do
  it 'register itself' do
    expect(Itly.plugins).to eq([Itly::AmplitudePlugin])
  end
end
