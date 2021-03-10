# frozen_string_literal: true

describe Itly::Plugin::Iteratively::TrackType do
  it 'constants' do
    expect(Itly::Plugin::Iteratively::TrackType::GROUP).to eq('group')
    expect(Itly::Plugin::Iteratively::TrackType::IDENTIFY).to eq('identify')
    expect(Itly::Plugin::Iteratively::TrackType::TRACK).to eq('track')
  end
end
