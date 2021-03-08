# frozen_string_literal: true

describe Itly::PluginIteratively::TrackType do
  it 'constants' do
    expect(Itly::PluginIteratively::TrackType::GROUP).to eq('group')
    expect(Itly::PluginIteratively::TrackType::IDENTIFY).to eq('identify')
    expect(Itly::PluginIteratively::TrackType::TRACK).to eq('track')
  end
end
