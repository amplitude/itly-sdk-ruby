# frozen_string_literal: true

describe Itly::Plugin::IterativelyOptions do
  include RspecLoggerHelpers

  it 'constants' do
    expect(Itly::Plugin::IterativelyOptions::DEFAULT_URL).to eq('https://data-us-east1.iterative.ly/t')
  end

  describe 'instance attributes' do
    let(:plugin_options) { Itly::Plugin::IterativelyOptions.new }

    it 'can read' do
      %i[url disabled flush_queue_size batch_size flush_interval_ms max_retries retry_delay_min
         retry_delay_max omit_values branch version].each do |attr|
        expect(plugin_options.respond_to?(attr)).to be(true)
      end
    end

    it 'cannot write' do
      %i[url disabled flush_queue_size batch_size flush_interval_ms max_retries retry_delay_min
         retry_delay_max omit_values branch version].each do |attr|
        expect(plugin_options.respond_to?(:"#{attr}=")).to be(false)
      end
    end
  end

  describe '#initialize' do
    describe 'default values' do
      let!(:plugin_options) { Itly::Plugin::IterativelyOptions.new }

      it do
        expect(plugin_options.instance_variable_get('@url')).to eq('https://data-us-east1.iterative.ly/t')
        expect(plugin_options.instance_variable_get('@disabled')).to be(nil)
        expect(plugin_options.instance_variable_get('@flush_queue_size')).to eq(10)
        expect(plugin_options.instance_variable_get('@batch_size')).to eq(100)
        expect(plugin_options.instance_variable_get('@flush_interval_ms')).to eq(10_000)
        expect(plugin_options.instance_variable_get('@max_retries')).to eq(25)
        expect(plugin_options.instance_variable_get('@retry_delay_min')).to eq(10.0)
        expect(plugin_options.instance_variable_get('@retry_delay_max')).to eq(3600.0)
        expect(plugin_options.instance_variable_get('@omit_values')).to be(false)
        expect(plugin_options.instance_variable_get('@branch')).to be(nil)
        expect(plugin_options.instance_variable_get('@version')).to be(nil)
      end
    end

    describe 'overwrite defaults' do
      let!(:plugin_options) do
        Itly::Plugin::IterativelyOptions.new \
          url: 'http://url', disabled: true,
          flush_queue_size: 1, batch_size: 5, flush_interval_ms: 6, max_retries: 2,
          retry_delay_min: 3.0, retry_delay_max: 4.0, omit_values: true,
          branch: 'feature/new', version: '1.2.3'
      end

      it do
        expect(plugin_options.instance_variable_get('@url')).to eq('http://url')
        expect(plugin_options.instance_variable_get('@disabled')).to be(true)
        expect(plugin_options.instance_variable_get('@flush_queue_size')).to eq(1)
        expect(plugin_options.instance_variable_get('@batch_size')).to eq(5)
        expect(plugin_options.instance_variable_get('@flush_interval_ms')).to eq(6)
        expect(plugin_options.instance_variable_get('@max_retries')).to eq(2)
        expect(plugin_options.instance_variable_get('@retry_delay_min')).to eq(3.0)
        expect(plugin_options.instance_variable_get('@retry_delay_max')).to eq(4.0)
        expect(plugin_options.instance_variable_get('@omit_values')).to be(true)
        expect(plugin_options.instance_variable_get('@branch')).to eq('feature/new')
        expect(plugin_options.instance_variable_get('@version')).to eq('1.2.3')
      end
    end
  end
end
