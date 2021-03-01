# frozen_string_literal: true

describe Itly::Plugin do
  it '#load' do
    expect { Itly::Plugin.new.load options: Itly::Options.new }.to raise_error(NotImplementedError)
  end

  describe '#get_plugin_options' do
    context 'root class' do
      before do
        Object.const_set 'TestPluginOptions', Class.new(Itly::Plugin)
      end

      after do
        Object.send :remove_const, 'TestPluginOptions'
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

    context 'nested class' do
      before do
        Object.const_set 'TestParentClass', Class.new
        TestParentClass.const_set 'TestPluginOptions', Class.new(Itly::Plugin)
      end

      after do
        TestParentClass.send :remove_const, 'TestPluginOptions'
        Object.send :remove_const, 'TestParentClass'
      end

      let(:plugin) { TestParentClass::TestPluginOptions.new }
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

  describe '#plugin_id' do
    context 'root class' do
      before do
        Object.const_set 'TestPluginId', Class.new(Itly::Plugin)
      end

      after do
        Object.send :remove_const, 'TestPluginId'
      end

      it do
        expect(TestPluginId.new.send :plugin_id).to eq('test_plugin_id')
      end
    end

    context 'nested class' do
      before do
        Object.const_set 'TestPluginId', Class.new
        TestPluginId.const_set 'NestedClass', Class.new(Itly::Plugin)
      end

      after do
        TestPluginId.send :remove_const, 'NestedClass'
        Object.send :remove_const, 'TestPluginId'
      end

      it do
        expect(TestPluginId::NestedClass.new.send :plugin_id).to eq('nested_class')
      end
    end
  end
end
