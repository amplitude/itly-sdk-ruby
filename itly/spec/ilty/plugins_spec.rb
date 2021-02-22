# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
describe Itly::Plugins do
  describe 'class attributes' do
    it 'default values' do
      expect(Itly.plugins).to eq([])
    end

    it 'can read' do
      expect(Itly.respond_to?(:plugins)).to be(true)
    end

    it 'cannot write' do
      expect(Itly.respond_to?(:plugins=)).to be(false)
    end
  end

  describe 'instance attributes' do
    it 'default values' do
      expect(Itly.new.plugins_instances).to eq([])
    end

    it 'can read' do
      expect(Itly.new.respond_to?(:plugins_instances)).to be(true)
    end

    it 'cannot write' do
      expect(Itly.new.respond_to?(:plugins_instances=)).to be(false)
    end
  end

  describe 'initialize' do
    before do
      expect_any_instance_of(Itly).to receive(:instantiate_plugins)
      expect_any_instance_of(Itly).to receive(:send_to_plugins).with(:init)
    end

    let!(:itly) { Itly.new }

    it do
      expect(itly.plugins_instances).to eq([])
    end
  end

  describe '#instantiate_plugins', :unload_itly, fake_plugins: 2 do
    before do
      expect_any_instance_of(Itly).to receive(:instantiate_plugins).and_call_original
      expect_any_instance_of(Itly).to receive(:send_to_plugins).with(:init)
    end

    let!(:itly) { Itly.new }

    it 'instanciates all registered plugins' do
      instances = itly.plugins_instances
      expect(instances.length).to eq(2)
      expect(instances[0]).to be_a(FakePlugin0)
      expect(instances[1]).to be_a(FakePlugin1)
    end
  end

  describe '#send_to_plugins', :unload_itly, fake_plugins: 2, fake_plugins_methods: [:some_method, :init] do
    # Instantiate 2 FakePlugin
    let!(:itly) { Itly.new }

    let!(:plugin_a) { itly.plugins_instances[0] }
    let!(:plugin_b) { itly.plugins_instances[1] }

    # Set expectation
    before do
      expect(plugin_a).to receive(:some_method).with('param 1', 2, :param3)
      expect(plugin_b).to receive(:some_method).with('param 1', 2, :param3)
    end

    # Call method
    it 'send message to all instanciated plugins' do
      itly.send :send_to_plugins, :some_method, 'param 1', 2, :param3
    end
  end
end
# rubocop:enable Metrics/BlockLength
