# frozen_string_literal: true

describe Itly::PluginMixpanel::ErrorHandler do
  describe 'error' do
    let(:handler) { Itly::PluginMixpanel::ErrorHandler.new }

    it do
      expect do
        handler.handle 'Error Message'
      end.to raise_error(Itly::RemoteError, 'The client returned an error: Error Message')
    end
  end
end
