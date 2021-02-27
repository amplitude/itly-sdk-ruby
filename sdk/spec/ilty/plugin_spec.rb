# frozen_string_literal: true

describe Itly::Plugin do
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
