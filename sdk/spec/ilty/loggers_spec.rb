# frozen_string_literal: true

describe Itly::Loggers do
  it 'self.itly_dot_log' do
    expect(Itly::Loggers.itly_dot_log).to be_a_kind_of(Logger)
  end

  it 'self.std_out' do
    expect(Itly::Loggers.std_out).to be_a_kind_of(Logger)
  end

  it 'self.nil' do
    expect(Itly::Loggers.nil_logger).to be(nil)
  end
end
