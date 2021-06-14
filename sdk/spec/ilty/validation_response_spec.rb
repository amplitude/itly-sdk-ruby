# frozen_string_literal: true

describe Itly::ValidationResponse do
  describe 'instance attributes' do
    let(:object) { Itly::ValidationResponse.new valid: true, plugin_id: 'ABC', message: 'text' }

    it 'can read' do
      expect(object.respond_to?(:valid)).to be(true)
      expect(object.respond_to?(:plugin_id)).to be(true)
      expect(object.respond_to?(:message)).to be(true)
    end

    it 'can write' do
      expect(object.respond_to?(:valid=)).to be(false)
      expect(object.respond_to?(:plugin_id=)).to be(false)
      expect(object.respond_to?(:message=)).to be(false)
    end
  end

  describe '#initialize' do
    describe 'default' do
      let(:object) { Itly::ValidationResponse.new valid: true, plugin_id: 'ABC', message: 'text' }

      it do
        expect(object.valid).to be(true)
        expect(object.plugin_id).to eq('ABC')
        expect(object.message).to eq('text')
      end
    end

    describe 'without message' do
      let(:object) { Itly::ValidationResponse.new valid: true, plugin_id: 'ABC' }

      it do
        expect(object.valid).to be(true)
        expect(object.plugin_id).to eq('ABC')
        expect(object.message).to eq('')
      end
    end
  end
end
