# frozen_string_literal: true

describe Itly::Plugin::Amplitude::CallOptions do
  let(:props) do
    %w[
      device_id time groups app_version platform os_name os_version device_brand device_manufacturer
      device_model carrier country region city dma language price quantity revenue productId revenueType
      location_lat location_lng ip idfa idfv adid android_id event_id session_id insert_id
    ]
  end

  describe 'instance attributes' do
    let(:options) { Itly::Plugin::Amplitude::CallOptions.new }

    it do
      props.each do |prop|
        expect(options.respond_to?(prop)).to be(true)
        expect(options.respond_to?(:"#{prop}=")).to be(false)
      end
    end
  end

  describe '#initialize' do
    describe 'default values' do
      let(:options) { Itly::Plugin::Amplitude::CallOptions.new }

      it do
        expect(options.callback).to be(nil)
        props.each do |prop|
          expect(options.send(prop)).to be(nil)
        end
      end
    end

    describe 'with values' do
      let(:props_with_values) do
        integer_keys = %w[time session_id event_id quantity]
        float_keys = %w[location_lng location_lat revenue price]
        hash_keys = %w[groups]

        (props - integer_keys - float_keys - hash_keys).collect.with_index { |v, i| [v.to_sym, i.to_s] }.to_h
          .merge(integer_keys.collect.with_index { |v, i| [v.to_sym, i] }.to_h)
          .merge(float_keys.collect.with_index { |v, i| [v.to_sym, i.to_f] }.to_h)
          .merge(hash_keys.collect.with_index { |v, i| [v.to_sym, { 'data' => i }] }.to_h)
      end

      let(:callback) { ->(_a, _b) {} }
      let(:options) { Itly::Plugin::Amplitude::CallOptions.new(**props_with_values.merge(callback: callback)) }

      it do
        expect(options.callback).to eq(callback)
        props_with_values.each do |(prop, val)|
          expect(options.send(prop)).to eq(val)
        end
      end
    end
  end

  describe 'to_hash' do
    describe 'without values' do
      let(:options) { Itly::Plugin::Amplitude::CallOptions.new }

      it do
        expect(options.to_hash).to eq({})
      end
    end

    describe 'with values' do
      let(:callback) { ->(_a, _b) {} }
      let(:options) do
        Itly::Plugin::Amplitude::CallOptions.new callback: callback, device_id: 'DEVID', time: 123_456, country: ''
      end

      it do
        expect(options.to_hash).to eq({ device_id: 'DEVID', time: 123_456, country: '' })
      end
    end
  end

  describe 'to_s' do
    describe 'without values' do
      let(:options) { Itly::Plugin::Amplitude::CallOptions.new }

      it do
        expect(options.to_s).to eq('#<Amplitude::CallOptions callback: nil>')
      end
    end

    describe 'with values' do
      let(:callback) { ->(_a, _b) {} }
      let(:options) do
        Itly::Plugin::Amplitude::CallOptions.new callback: callback, device_id: 'DEVID', time: 123_456
      end

      it do
        expect(options.to_s).to eq(
          '#<Amplitude::CallOptions callback: provided device_id: DEVID time: 123456>'
        )
      end
    end
  end
end
