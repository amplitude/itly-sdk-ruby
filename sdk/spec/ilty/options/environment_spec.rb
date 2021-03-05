# frozen_string_literal: true

describe Itly::Options::Environment do
  it 'constants' do
    expect(Itly::Options::Environment::DEVELOPMENT).to eq(:development)
    expect(Itly::Options::Environment::PRODUCTION).to eq(:production)
  end
end

describe Itly::Options do
  let(:options) { Itly::Options.new }

  it 'development' do
    options.environment = Itly::Options::Environment::DEVELOPMENT
    expect(options.development?).to be(true)
    expect(options.production?).to be(false)
  end

  it 'production' do
    options.environment = Itly::Options::Environment::PRODUCTION
    expect(options.development?).to be(false)
    expect(options.production?).to be(true)
  end
end