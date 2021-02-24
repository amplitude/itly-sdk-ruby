# frozen_string_literal: true

describe Itly::EnvironmentOptions do
  it 'constants' do
    expect(Itly::EnvironmentOptions::DEVELOPMENT).to eq(:development)
    expect(Itly::EnvironmentOptions::PRODUCTION).to eq(:production)
  end
end
