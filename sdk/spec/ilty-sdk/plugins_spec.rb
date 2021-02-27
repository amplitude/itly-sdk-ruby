# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
describe Itly::Plugins do
  describe 'class attributes' do
    it 'default values' do
      expect(Itly.registered_plugins).to eq([])
    end

    it 'can read' do
      expect(Itly.respond_to?(:registered_plugins)).to be(true)
    end

    it 'cannot write' do
      expect(Itly.respond_to?(:registered_plugins=)).to be(false)
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
      itly.send :instantiate_plugins
    end

    it do
      instances = itly.plugins_instances
      expect(instances.length).to eq(2)
      expect(instances[0]).to be_a(FakePlugin0)
      expect(instances[1]).to be_a(FakePlugin1)
    end
  end

  describe '#run_on_plugins', :unload_itly, fake_plugins_methods: %i[some_method load] do
    create_itly_object

    let!(:plugin_a) { itly.plugins_instances[0] }
    let!(:plugin_b) { itly.plugins_instances[1] }

    describe 'call lambda with each plugin', fake_plugins: 2 do
      before do
        expect(plugin_a).to receive(:some_method).with('param 1', 2, :param3)
        expect(plugin_b).to receive(:some_method).with('param 1', 2, :param3)

        expect(itly.options.logger).not_to receive(:error)
      end

      it do
        itly.send :run_on_plugins, lambda { |plugin|
          plugin.some_method 'param 1', 2, :param3
        }
      end
    end

    describe 'rescue exceptions', fake_plugins: 2 do
      before do
        expect(plugin_a).to receive(:some_method).and_raise('Testing 1 2 3')
        expect(plugin_b).to receive(:some_method).with(:params)

        expect(itly.options.logger).to receive(:error)
          .with('Itly Error in FakePlugin0. RuntimeError: Testing 1 2 3')
      end

      it do
        itly.send :run_on_plugins, lambda { |plugin|
          plugin.some_method :params
        }
      end
    end

    describe 'collect returning values', fake_plugins: 4 do
      let!(:plugin_c) { itly.plugins_instances[2] }
      let!(:plugin_d) { itly.plugins_instances[3] }

      before do
        expect(plugin_a).to receive(:some_method).and_return(:val1)
        expect(plugin_b).to receive(:some_method).and_raise('Test')
        expect(plugin_c).to receive(:some_method).and_return(:val2)
        expect(plugin_d).to receive(:some_method).and_return(nil)

        expect(itly.options.logger).to receive(:error)
      end

      it do
        expect(
          itly.send(:run_on_plugins, lambda { |plugin|
            plugin.some_method :params
          })
        ).to eq(%i[val1 val2])
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
