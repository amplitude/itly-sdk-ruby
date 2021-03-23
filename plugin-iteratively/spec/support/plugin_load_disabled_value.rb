# frozen_string_literal: true

shared_examples 'plugin load disabled value' do |environment:, expected:, disabled: nil|
  context "environment=#{environment} disabled=#{disabled.nil? ? '(default)' : disabled}" do
    let(:options) do
      o = {
        url: 'http://url',
        api_key: 'key123'
      }
      o[:disabled] = disabled unless disabled.nil?
      o
    end
    let(:plugin) { Itly::Plugin::Iteratively.new(**options) }

    context 'load disabled is unset' do
      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = fake_logger
          options.environment = environment
        end
      end

      it do
        expect(plugin.disabled).to be(expected)
      end
    end

    context 'load disabled is true' do
      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = fake_logger
          options.environment = environment
          options.disabled = true
        end
      end

      it do
        expect(plugin.disabled).to be(expected)
      end
    end

    context 'load disabled is false' do
      before do
        itly.load do |options|
          options.plugins = [plugin]
          options.logger = fake_logger
          options.environment = environment
          options.disabled = false
        end
      end

      it do
        expect(plugin.disabled).to be(expected)
      end
    end
  end
end
