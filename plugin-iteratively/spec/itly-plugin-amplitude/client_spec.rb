# frozen_string_literal: true

describe Itly::PluginIteratively::Client do
  describe 'instance attributes' do
    let(:client) { Itly::PluginIteratively::Client.new url: 'http://url', api_key: 'key123' }

    it 'can read' do
      expect(client.respond_to?(:url)).to be(true)
      expect(client.respond_to?(:api_key)).to be(true)
    end

    it 'cannot write' do
      expect(client.respond_to?(:url=)).to be(false)
      expect(client.respond_to?(:api_key=)).to be(false)
    end
  end

  describe '#initialize' do
    let!(:client) { Itly::PluginIteratively::Client.new url: 'http://url', api_key: 'key123' }

    it do
      expect(client.instance_variable_get('@url')).to eq('http://url')
      expect(client.instance_variable_get('@api_key')).to eq('key123')
    end
  end
end
