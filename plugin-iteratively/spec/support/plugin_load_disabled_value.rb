# frozen_string_literal: true

shared_examples 'plugin load disabled value' do |environment:, expected:, disabled: nil|
  context "environment=#{environment} disabled=#{disabled.nil? ? '(default)' : disabled}" do
    before do
      itly.load do |options|
        options.plugins = [plugin]
        options.logger = fake_logger
        options.environment = environment
        options.disabled = disabled unless disabled.nil?
      end
    end

    it do
      expect(plugin.disabled).to be(expected)
    end
  end
end
