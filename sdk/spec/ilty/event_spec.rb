# frozen_string_literal: true

describe Itly::Event do
  describe 'instance attributes' do
    describe 'default values' do
      let(:event) { Itly::Event.new name: 'the_event' }

      it 'should match expected' do
        expect(event.name).to eq('the_event')
        expect(event.properties).to eq({})
        expect(event.id).to be(nil)
        expect(event.version).to be(nil)
        expect(event.plugins).to eq({})
      end
    end

    describe 'constructor params' do
      let(:event) do
        Itly::Event.new \
          name: 'the_event', properties: { a: 'b' }, id: '123', version: '2.1.6', plugins: { plugin_a: false }
      end

      it 'should set attribute values' do
        expect(event.name).to eq('the_event')
        expect(event.properties).to eq(a: 'b')
        expect(event.id).to eq('123')
        expect(event.version).to eq('2.1.6')
        expect(event.plugins).to eq('plugin_a' => false)
      end
    end

    describe 'property access' do
      let(:event) { Itly::Event.new name: 'the_event' }

      it 'should be read only' do
        %i[name properties id version plugins].each do |attribute|
          expect(event.respond_to?(attribute)).to be(true)
          expect(event.respond_to?(:"#{attribute}=")).to be(false)
        end
      end
    end
  end

  describe '#to_s' do
    describe 'default values' do
      let(:event) { Itly::Event.new name: 'the_event' }

      it do
        expect(event.to_s).to eq('#<Itly::Event: name: the_event, properties: {}>')
      end
    end

    describe 'with all values' do
      let(:event) { Itly::Event.new name: 'the_event', id: '159', version: '1.2.3' }

      it do
        expect(event.to_s).to eq('#<Itly::Event: name: the_event, id: 159, version: 1.2.3, properties: {}>')
      end
    end
  end
end
