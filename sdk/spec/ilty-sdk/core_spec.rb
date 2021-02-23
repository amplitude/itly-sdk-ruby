# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
describe 'Itly' do
  describe 'alias', :unload_itly, fake_plugins: 2, fake_plugins_methods: %i[init] do
    context 'default' do
      let!(:itly) { Itly.new }

      let!(:plugin_a) { itly.plugins_instances[0] }
      let!(:plugin_b) { itly.plugins_instances[1] }

      before do
        expect(itly.options.logger).to receive(:info)
          .with('alias(user_id: 123, previous_id: 456)')

        expect(plugin_a).to receive(:alias).with(user_id: '123', previous_id: '456')
        expect(plugin_b).to receive(:alias).with(user_id: '123', previous_id: '456')
        expect(plugin_a).to receive(:post_alias).with(user_id: '123', previous_id: '456')
        expect(plugin_b).to receive(:post_alias).with(user_id: '123', previous_id: '456')
      end

      it do
        itly.alias user_id: '123', previous_id: '456'
      end
    end

    context 'disabled' do
      let!(:itly) do
        Itly.new { |o| o.disabled = true }
      end

      let!(:plugin_a) { itly.plugins_instances[0] }
      let!(:plugin_b) { itly.plugins_instances[1] }

      before do
        expect(itly.options.logger).not_to receive(:info)

        expect(plugin_a).not_to receive(:alias)
        expect(plugin_b).not_to receive(:alias)
        expect(plugin_a).not_to receive(:post_alias)
        expect(plugin_b).not_to receive(:post_alias)
      end

      it do
        itly.alias user_id: '123', previous_id: '456'
      end
    end
  end

  describe 'flush', :unload_itly, fake_plugins: 2, fake_plugins_methods: %i[init] do
    context 'default' do
      let!(:itly) { Itly.new }

      let!(:plugin_a) { itly.plugins_instances[0] }
      let!(:plugin_b) { itly.plugins_instances[1] }

      before do
        expect(itly.options.logger).to receive(:info).with('flush()')

        expect(plugin_a).to receive(:flush)
        expect(plugin_b).to receive(:flush)
      end

      it do
        itly.flush
      end
    end

    context 'disabled' do
      let!(:itly) do
        Itly.new { |o| o.disabled = true }
      end

      let!(:plugin_a) { itly.plugins_instances[0] }
      let!(:plugin_b) { itly.plugins_instances[1] }

      before do
        expect(itly.options.logger).not_to receive(:info)

        expect(plugin_a).not_to receive(:flush)
        expect(plugin_b).not_to receive(:flush)
      end

      it do
        itly.flush
      end
    end
  end

  describe 'reset', :unload_itly, fake_plugins: 2, fake_plugins_methods: %i[init] do
    context 'default' do
      let!(:itly) { Itly.new }

      let!(:plugin_a) { itly.plugins_instances[0] }
      let!(:plugin_b) { itly.plugins_instances[1] }

      before do
        expect(itly.options.logger).to receive(:info).with('reset()')

        expect(plugin_a).to receive(:reset)
        expect(plugin_b).to receive(:reset)
      end

      it do
        itly.reset
      end
    end

    context 'disabled' do
      let!(:itly) do
        Itly.new { |o| o.disabled = true }
      end

      let!(:plugin_a) { itly.plugins_instances[0] }
      let!(:plugin_b) { itly.plugins_instances[1] }

      before do
        expect(itly.options.logger).not_to receive(:info)

        expect(plugin_a).not_to receive(:reset)
        expect(plugin_b).not_to receive(:reset)
      end

      it do
        itly.reset
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
