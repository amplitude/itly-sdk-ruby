# frozen_string_literal: true

shared_examples 'runs on plugins' do |method:, method_params: nil, no_post_method: false, expected_log_info: nil|
  context 'default', fake_plugins: 2, fake_plugins_methods: %i[load] do
    create_itly_object

    let!(:plugin_a) { itly.plugins_instances[0] }
    let!(:plugin_b) { itly.plugins_instances[1] }

    before do
      if expected_log_info
        expect(itly.options.logger).to receive(:info).with(expected_log_info)
      else
        expect(itly.options.logger).not_to receive(:info)
      end

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

    it do
      if method_params
        itly.send method, method_params
      else
        itly.send method
      end
    end
  end

  context 'disabled', fake_plugins: 2, fake_plugins_methods: %i[load] do
    create_itly_object disabled: true

    let!(:plugin_a) { itly.plugins_instances[0] }
    let!(:plugin_b) { itly.plugins_instances[1] }

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
        itly.send method, method_params
      else
        itly.send method
      end
    end
  end
end
