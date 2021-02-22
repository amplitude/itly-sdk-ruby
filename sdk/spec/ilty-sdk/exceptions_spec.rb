# frozen_string_literal: true

describe Itly::InitializationError do
  it do
    expect(Itly::InitializationError.superclass).to eq(StandardError)
  end
end
