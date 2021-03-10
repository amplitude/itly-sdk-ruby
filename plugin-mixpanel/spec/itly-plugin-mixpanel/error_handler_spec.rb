# frozen_string_literal: true

describe Itly::Plugin::Mixpanel::ErrorHandler do
  describe 'error' do
    let(:handler) { Itly::Plugin::Mixpanel::ErrorHandler.new }

    it do
      expect do
        handler.handle 'Error Message'
      end.to raise_error(Itly::RemoteError, 'The client returned an error: Error Message')
    end
  end
end
