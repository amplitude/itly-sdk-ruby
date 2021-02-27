# frozen_string_literal: true

describe Itly::OptionsWrapper do
  describe 'default values' do
    let(:wrapper) { Itly::OptionsWrapper.new }
    let(:values) { wrapper.instance_variable_get '@values' }

    it do
      expect(values).to eq({})
    end
  end

  describe '#clear!' do
    let(:wrapper) { Itly::OptionsWrapper.new }
    let(:values) { wrapper.instance_variable_get '@values' }

    before do
      wrapper.instance_variable_set '@values', { a: 1 }
      expect(values).to eq(a: 1)
    end

    it do
      wrapper.clear!
      expect(values).to eq({})
    end
  end

  describe 'wrap values' do
    let(:wrapper) { Itly::OptionsWrapper.new }
    let(:values) { wrapper.instance_variable_get '@values' }

    it 'set value' do
      wrapper.this_is_a_key = 'and this is a value'
      expect(values).to eq(this_is_a_key: 'and this is a value')
    end

    it 'get value' do
      wrapper.a_key = 'a value'
      expect(wrapper.a_key).to eq('a value')
    end

    it 'undefined value' do
      expect { wrapper.a_key }.to raise_error(NoMethodError)
    end
  end

  describe 'respond_to?' do
    let(:wrapper) { Itly::OptionsWrapper.new }

    before do
      expect(wrapper.respond_to?(:a_key)).to be(false)
    end

    it do
      wrapper.a_key = 'a value'
      expect(wrapper.respond_to?(:a_key)).to be(true)
    end
  end
end
