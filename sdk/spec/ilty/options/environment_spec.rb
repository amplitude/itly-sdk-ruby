# frozen_string_literal: true

describe Itly::Options::Environment do
  it 'constants' do
    expect(Itly::Options::Environment::DEVELOPMENT).to eq(:development)
    expect(Itly::Options::Environment::PRODUCTION).to eq(:production)
  end
end
