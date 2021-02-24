# frozen_string_literal: true

describe Itly::ValidationOptions do
  it 'constants' do
    expect(Itly::ValidationOptions::DEFAULT).to eq(-1)
    expect(Itly::ValidationOptions::DISABLED).to eq(0)
    expect(Itly::ValidationOptions::TRACK_INVALID).to eq(1)
    expect(Itly::ValidationOptions::ERROR_ON_INVALID).to eq(2)
  end
end
