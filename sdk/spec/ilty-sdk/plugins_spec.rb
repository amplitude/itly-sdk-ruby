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

  describe '#instantiate_plugins', :unload_itly, fake_plugins: 2 do
    let!(:itly) { Itly.new }

    before do
      expect(itly).to receive(:instantiate_plugins).and_call_original
      expect(itly).to receive(:send_to_plugins).and_wrap_original do |_, *args|
        expect(args.count).to eq(2)
        expect(args[0]).to eq(:init)
        expect(args[1].keys).to eq([:options])
        expect(args[1][:options].class).to eq(Itly::Options)
      end
    end

    it 'instanciates all registered plugins' do
      itly.load

      instances = itly.plugins_instances
      expect(instances.length).to eq(2)
      expect(instances[0]).to be_a(FakePlugin0)
      expect(instances[1]).to be_a(FakePlugin1)
    end
  end

  describe '#send_to_plugins', :unload_itly, fake_plugins: 2, fake_plugins_methods: %i[some_method init] do
    create_itly_object

    let!(:plugin_a) { itly.plugins_instances[0] }
    let!(:plugin_b) { itly.plugins_instances[1] }

    describe 'send message to all plugins' do
      before do
        expect(plugin_a).to receive(:some_method).with('param 1', 2, :param3)
        expect(plugin_b).to receive(:some_method).with('param 1', 2, :param3)

        expect(itly.options.logger).not_to receive(:error)
      end

      it 'send message to all instanciated plugins' do
        itly.send :send_to_plugins, :some_method, 'param 1', 2, :param3
      end
    end

    describe 'rescue exceptions' do
      before do
        expect(plugin_a).to receive(:some_method).and_raise('Testing 1 2 3')
        expect(plugin_b).to receive(:some_method).with(:params)

        expect(itly.options.logger).to receive(:error)
          .with('Itly Error in FakePlugin0. RuntimeError: Testing 1 2 3')
      end

      it 'send message to all instanciated plugins' do
        itly.send :send_to_plugins, :some_method, :params
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
