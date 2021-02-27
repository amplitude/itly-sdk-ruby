# frozen_string_literal: true

describe Itly do
  it 'VERSION constant' do
    expect(Itly::VERSION).to match(/^\d+\.\d+\.\d+$/)
  end
end
