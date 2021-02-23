# frozen_string_literal: true

describe Itly::Plugin do
  describe 'self.register_plugin' do
    before do
      Object.const_set 'TestPluginRegister', Class.new
      expect(Itly.plugins).to eq([])
    end

    after do
      Itly.plugins.clear
      Object.send :remove_const, :TestPluginRegister
    end

    it 'add plugin class `plugins` module attribute' do
      Itly::Plugin.register_plugin TestPluginRegister
      expect(Itly.plugins).to eq([TestPluginRegister])
    end
  end

  it 'init' do
    expect { Itly::Plugin.new.init options: Itly::Options.new }.to raise_error(NotImplementedError)
  end
end
