# frozen_string_literal: true

describe Itly::InitializationError do
  it do
    expect(Itly::InitializationError.superclass).to eq(StandardError)
  end
end

describe Itly::ValidationError do
  it do
    expect(Itly::ValidationError.superclass).to eq(StandardError)
  end
end


describe Itly::RemoteError do
  it do
    expect(Itly::RemoteError.superclass).to eq(StandardError)
  end
end
