# frozen_string_literal: true

describe Itly::Plugin::Snowplow::Options do
  describe 'instance attributes' do
    let(:options) { Itly::Plugin::Snowplow::Options.new endpoint: 'endpoint123' }

    it 'can read' do
      %i[endpoint protocol method buffer_size disabled].each do |attr|
        expect(options.respond_to?(attr)).to be(true)
      end
    end

    it 'cannot write' do
      %i[endpoint protocol method buffer_size disabled].each do |attr|
        expect(options.respond_to?(:"#{attr}=")).to be(false)
      end
    end
  end

  describe '#initialize' do
    let(:options) { Itly::Plugin::Snowplow::Options.new endpoint: 'endpoint123' }

    it do
      expect(options.endpoint).to eq('endpoint123')
      expect(options.protocol).to eq('http')
      expect(options.method).to eq('get')
      expect(options.buffer_size).to be(nil)
      expect(options.disabled).to be(false)
    end
  end
end
