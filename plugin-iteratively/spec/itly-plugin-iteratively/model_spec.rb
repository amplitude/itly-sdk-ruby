# frozen_string_literal: true

describe Itly::Plugin::Iteratively::Model do
  describe 'instance attributes' do
    let(:event) { Itly::Event.new name: 'test_event', properties: { data: 'value' } }
    let(:model) { Itly::Plugin::Iteratively::Model.new type: 'test_model', event: event }

    it 'can read' do
      %i[type date_sent event_id event_chema_version event_name properties valid validation].each do |attribute|
        expect(model.respond_to?(attribute)).to be(true)
      end
    end

    it 'cannot write' do
      %i[type date_sent event_id event_chema_version event_name properties valid validation].each do |attribute|
        expect(model.respond_to?(:"#{attribute}=")).to be(false)
      end
    end
  end

  describe '#initialize' do
    let(:event) { Itly::Event.new name: 'test_event', id: 'id123', version: '12', properties: { data: 'value' } }

    context 'without validation' do
      let!(:model) { Itly::Plugin::Iteratively::Model.new type: 'test_model', event: event }

      it do
        expect(model.instance_variable_get('@type')).to eq('test_model')
        expect(model.instance_variable_get('@date_sent')).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/)
        expect(model.instance_variable_get('@event_id')).to eq('id123')
        expect(model.instance_variable_get('@event_chema_version')).to eq('12')
        expect(model.instance_variable_get('@event_name')).to eq('test_event')
        expect(model.instance_variable_get('@properties')).to eq(data: 'value')
        expect(model.instance_variable_get('@valid')).to be(nil)
        expect(model.instance_variable_get('@validation')).to be(nil)
      end
    end

    context 'with validation' do
      let!(:validation) { Itly::ValidationResponse.new valid: false, plugin_id: 'id', message: 'Validation Msg' }
      let!(:model) { Itly::Plugin::Iteratively::Model.new type: 'test_model', event: event, validation: validation }

      it do
        expect(model.instance_variable_get('@type')).to eq('test_model')
        expect(model.instance_variable_get('@date_sent')).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/)
        expect(model.instance_variable_get('@event_id')).to eq('id123')
        expect(model.instance_variable_get('@event_chema_version')).to eq('12')
        expect(model.instance_variable_get('@event_name')).to eq('test_event')
        expect(model.instance_variable_get('@properties')).to eq(data: 'value')
        expect(model.instance_variable_get('@valid')).to be(false)
        expect(model.instance_variable_get('@validation')).to eq('Validation Msg')
      end
    end
  end

  describe '#to_json' do
    let(:event) { Itly::Event.new name: 'test_event', id: 'id123', version: '12', properties: { data: 'value' } }

    context 'without validation' do
      let!(:model) { Itly::Plugin::Iteratively::Model.new type: 'test_model', event: event }

      let(:expected) do
        /^{"type":"test_model","dateSent":"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z","eventId":"id123",
          "eventChemaVersion":"12","eventName":"test_event","properties":{"data":"value"},
          "valid":null,"validation":null}$/x
      end

      it do
        expect(model.to_json).to match(expected)
      end
    end

    context 'with validation' do
      let!(:validation) { Itly::ValidationResponse.new valid: false, plugin_id: 'id', message: 'Validation Msg' }
      let!(:model) { Itly::Plugin::Iteratively::Model.new type: 'test_model', event: event, validation: validation }

      let(:expected) do
        /^{"type":"test_model","dateSent":"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z","eventId":"id123",
          "eventChemaVersion":"12","eventName":"test_event","properties":{"data":"value"},
          "valid":false,"validation":"Validation\sMsg"}$/x
      end

      it do
        expect(model.to_json).to match(expected)
      end
    end
  end
end