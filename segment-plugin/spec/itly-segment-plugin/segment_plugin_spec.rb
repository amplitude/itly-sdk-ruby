# frozen_string_literal: true

describe Itly::SegmentPlugin do
  it 'register itself' do
    expect(Itly.registered_plugins).to eq([Itly::SegmentPlugin])
  end

end
