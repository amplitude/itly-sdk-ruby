# frozen_string_literal: true

describe Itly::Plugins do
  describe '#run_on_plugins', fake_plugins_methods: %i[some_method] do
    describe 'call lambda with each plugin', fake_plugins: 2 do
      let!(:fake_logger) { double 'logger', info: nil, warn: nil }
      let!(:plugin_a) { FakePlugin0.new }
      let!(:plugin_b) { FakePlugin1.new }
      let!(:itly) { Itly.new }

      before do
        itly.load do |options|
          options.plugins = [plugin_a, plugin_b]
          options.logger = fake_logger
        end
      end

      before do
        expect(plugin_a).to receive(:some_method).with('param 1', 2, :param3)
        expect(plugin_b).to receive(:some_method).with('param 1', 2, :param3)

        expect(itly.options.logger).not_to receive(:error)
      end

      it do
        itly.send(:run_on_plugins) { |plugin| plugin.some_method 'param 1', 2, :param3 }
      end
    end

    describe 'rescue exceptions', fake_plugins: 2 do
      context 'development' do
        let!(:fake_logger) { double 'logger', info: nil, warn: nil }
        let!(:plugin_a) { FakePlugin0.new }
        let!(:plugin_b) { FakePlugin1.new }
        let!(:itly) { Itly.new }

        before do
          itly.load do |options|
            options.plugins = [plugin_a, plugin_b]
            options.environment = Itly::Options::Environment::DEVELOPMENT
            options.logger = fake_logger
          end
        end

        before do
          expect(plugin_a).to receive(:some_method).and_raise('Testing 1 2 3')
          expect(plugin_b).not_to receive(:some_method)

          expect(itly.options.logger).to receive(:error)
            .with('Itly Error in FakePlugin0. RuntimeError: Testing 1 2 3')
        end

        it do
          expect do
            itly.send(:run_on_plugins) { |plugin| plugin.some_method :params }
          end.to raise_error(RuntimeError, 'Testing 1 2 3')
        end
      end

      context 'production' do
        let!(:fake_logger) { double 'logger', info: nil, warn: nil }
        let!(:plugin_a) { FakePlugin0.new }
        let!(:plugin_b) { FakePlugin1.new }
        let!(:itly) { Itly.new }

        before do
          itly.load do |options|
            options.plugins = [plugin_a, plugin_b]
            options.environment = Itly::Options::Environment::PRODUCTION
            options.logger = fake_logger
          end
        end

        before do
          expect(plugin_a).to receive(:some_method).and_raise('Testing 1 2 3')
          expect(plugin_b).to receive(:some_method).with(:params)

          expect(itly.options.logger).to receive(:error)
            .with('Itly Error in FakePlugin0. RuntimeError: Testing 1 2 3')
        end

        it 'is expected to log error and continue running' do
          itly.send(:run_on_plugins) { |plugin| plugin.some_method :params }
        end
      end
    end

    describe 'collect returning values', fake_plugins: 4 do
      let!(:fake_logger) { double 'logger', info: nil, warn: nil }
      let!(:plugin_a) { FakePlugin0.new }
      let!(:plugin_b) { FakePlugin1.new }
      let!(:plugin_c) { FakePlugin2.new }
      let!(:plugin_d) { FakePlugin3.new }
      let!(:itly) { Itly.new }

      before do
        itly.load do |options|
          options.plugins = [plugin_a, plugin_b, plugin_c, plugin_d]
          options.environment = Itly::Options::Environment::PRODUCTION
          options.logger = fake_logger
        end
      end

      before do
        expect(plugin_a).to receive(:some_method).and_return(:val1)
        expect(plugin_b).to receive(:some_method).and_raise('Test')
        expect(plugin_c).to receive(:some_method).and_return(:val2)
        expect(plugin_d).to receive(:some_method).and_return(nil)

        expect(itly.options.logger).to receive(:error)
      end

      it do
        expect(
          itly.send(:run_on_plugins) { |plugin| plugin.some_method :params }
        ).to eq(%i[val1 val2])
      end
    end
  end
end
