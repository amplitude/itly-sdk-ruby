# frozen_string_literal: true

describe Itly::Plugin do
  describe '#plugin_id' do
    context 'root class' do
      before do
        Object.const_set 'TestPluginId', Class.new(Itly::Plugin)
      end

      after do
        Object.send :remove_const, 'TestPluginId'
      end

      it do
        expect(TestPluginId.new.send(:plugin_id)).to eq('test_plugin_id')
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
        expect(TestPluginId::NestedClass.new.send(:plugin_id)).to eq('test_plugin_id-nested_class')
      end
    end

    context 'nested class from Itly' do
      before do
        Itly.const_set 'NestedClass', Class.new(Itly::Plugin)
      end

      after do
        Itly.send :remove_const, 'NestedClass'
      end

      it do
        expect(Itly::NestedClass.new.send(:plugin_id)).to eq('nested_class')
      end
    end
  end
end
