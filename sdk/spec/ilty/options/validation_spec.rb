# frozen_string_literal: true

describe Itly::Options::Validation do
  it 'constants' do
    expect(Itly::Options::Validation::DISABLED).to eq(0)
    expect(Itly::Options::Validation::TRACK_INVALID).to eq(1)
    expect(Itly::Options::Validation::ERROR_ON_INVALID).to eq(2)
  end
end
