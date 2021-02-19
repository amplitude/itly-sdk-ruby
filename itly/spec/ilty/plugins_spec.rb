# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
describe Itly::Plugins do
  describe 'module attributes' do
    it 'default values' do
      expect(Itly::Plugins.plugins).to eq([])
      expect(Itly::Plugins.plugins_instances).to eq([])
    end

    it 'can read' do
      expect(Itly::Plugins.respond_to?(:plugins)).to be(true)
      expect(Itly::Plugins.respond_to?(:plugins_instances)).to be(true)
    end

    it 'cannot write' do
      expect(Itly::Plugins.respond_to?(:plugins=)).to be(false)
      expect(Itly::Plugins.respond_to?(:plugins_instances=)).to be(false)
    end
  end

  describe '#instantiate_plugins', :unload_itly, fake_plugins: 2 do
    before do
      Itly.instantiate_plugins
    end

    it 'instanciates all registered plugins' do
      instances = Itly::Plugins.plugins_instances
      expect(instances.length).to eq(2)
      expect(instances[0]).to be_a(FakePlugin0)
      expect(instances[1]).to be_a(FakePlugin1)
    end
  end

  describe '#send_to_plugins', :unload_itly, fake_plugins: 2, fake_plugins_methods: [:some_method] do
    # Instantiate 2 FakePlugin
    before do
      Itly.instantiate_plugins
    end

    let!(:plugin_a) { Itly::Plugins.plugins_instances[0] }
    let!(:plugin_b) { Itly::Plugins.plugins_instances[1] }

    # Set expectation
    before do
      expect(plugin_a).to receive(:some_method).with('param 1', 2, :param3)
      expect(plugin_b).to receive(:some_method).with('param 1', 2, :param3)
    end

    # Call method
    it 'send message to all instanciated plugins' do
      Itly.send_to_plugins :some_method, 'param 1', 2, :param3
    end
  end
end
# rubocop:enable Metrics/BlockLength
