# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
describe Itly::Plugin do
  describe 'self.register_plugin' do
    before do
      Object.const_set 'TestPluginRegister', Class.new
      expect(Itly.registered_plugins).to eq([])
    end

    after do
      Itly.registered_plugins.clear
      Object.send :remove_const, :TestPluginRegister
    end

    it 'add plugin class `plugins` module attribute' do
      Itly::Plugin.register_plugin TestPluginRegister
      expect(Itly.registered_plugins).to eq([TestPluginRegister])
    end
  end

  it '#load' do
    expect { Itly::Plugin.new.load options: Itly::Options.new }.to raise_error(NotImplementedError)
  end

  describe '#get_plugin_options' do
    before do
      Object.const_set 'TestPluginOptions', Class.new(Itly::Plugin)
    end

    after do
      Object.send :remove_const, :TestPluginOptions
    end

    let(:plugin) { TestPluginOptions.new }
    let(:options) { Itly::Options.new }

    it 'empty' do
      expect(plugin.send(:get_plugin_options, options)).to eq({})
    end

    describe 'with values' do
      before do
        options.plugins.test_plugin_options = { option_a: true, option_b: 'ABC' }
      end

      it do
        expect(plugin.send(:get_plugin_options, options)).to eq(option_a: true, option_b: 'ABC')
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
