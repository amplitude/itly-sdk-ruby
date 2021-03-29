# frozen_string_literal: true

shared_examples 'runs on plugins' do |method:, method_params: nil, no_post_method: false, expected_log_info: nil|
  context 'default', fake_plugins: 2 do
    # Instanciate plugins and Itly object
    let!(:fake_logger) { double 'logger', info: nil, warn: nil }
    let!(:plugin_a) { FakePlugin0.new }
    let!(:plugin_b) { FakePlugin1.new }
    let!(:itly) { Itly.new }

    # Load options
    before do
      itly.load do |options|
        options.plugins = [plugin_a, plugin_b]
        options.logger = fake_logger
      end
    end

    # Hook all expectations
    before do
      # Logger messages
      if expected_log_info
        expect(itly.options.logger).to receive(:info).with(expected_log_info)
      else
        expect(itly.options.logger).not_to receive(:info)
      end

      # Plugin targetted method and post method
      if method_params
        expect(plugin_a).to receive(method).with(method_params)
        expect(plugin_b).to receive(method).with(method_params)
        unless no_post_method
          expect(plugin_a).to receive(:"post_#{method}").with(method_params)
          expect(plugin_b).to receive(:"post_#{method}").with(method_params)
        end
      else
        expect(plugin_a).to receive(method)
        expect(plugin_b).to receive(method)
        unless no_post_method
          expect(plugin_a).to receive(:"post_#{method}")
          expect(plugin_b).to receive(:"post_#{method}")
        end
      end
    end

    # Run
    it do
      if method_params
        itly.send method, **method_params
      else
        itly.send method
      end
    end
  end

  context 'Itly was not ititialized' do
    let(:itly) { Itly.new }

    before do
      expect(itly).not_to receive(:run_on_plugins)
    end

    it do
      expect do
        if method_params
          itly.send method, **method_params
        else
          itly.send method
        end
      end.to raise_error(Itly::InitializationError, 'Itly is not initialized. Call #load { |options| ... }')
    end
  end

  context 'disabled', fake_plugins: 2 do
    let!(:fake_logger) { double 'logger', info: nil, warn: nil }
    let!(:plugin_a) { FakePlugin0.new }
    let!(:plugin_b) { FakePlugin1.new }
    let!(:itly) { Itly.new }

    # Load options
    before do
      itly.load do |options|
        options.disabled = true
        options.plugins = [plugin_a, plugin_b]
        options.logger = fake_logger
      end
    end

    before do
      expect(itly.options.logger).not_to receive(:info)

      expect(plugin_a).not_to receive(method)
      expect(plugin_b).not_to receive(method)
      unless no_post_method
        expect(plugin_a).not_to receive(:"post_#{method}")
        expect(plugin_b).not_to receive(:"post_#{method}")
      end
    end

    it do
      if method_params
        itly.send method, **method_params
      else
        itly.send method
      end
    end
  end
end
