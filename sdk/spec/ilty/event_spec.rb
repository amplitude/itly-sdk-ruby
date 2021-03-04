# frozen_string_literal: true

describe Itly::Event do
  describe 'instance attributes' do
    describe 'default values' do
      let(:event) { Itly::Event.new name: 'the_event' }

      it do
        expect(event.name).to eq('the_event')
        expect(event.properties).to eq({})
        expect(event.id).to be(nil)
        expect(event.version).to be(nil)
        expect(event.metadata).to be(nil)
      end
    end

    describe 'with params' do
      let(:event) do
        Itly::Event.new name: 'the_event', properties: { a: 'b' },
                        id: '123', version: '2.1.6', metadata: { some: 'data' }
      end

      it do
        expect(event.name).to eq('the_event')
        expect(event.properties).to eq(a: 'b')
        expect(event.id).to eq('123')
        expect(event.version).to eq('2.1.6')
        expect(event.metadata).to eq(some: 'data')
      end
    end

    describe 'attr_accessor' do
      let(:event) { Itly::Event.new name: 'the_event' }

      it do
        %i[name properties id version metadata].each do |attribute|
          expect(event.respond_to?(attribute)).to be(true)
          expect(event.respond_to?(:"#{attribute}=")).to be(true)
        end
      end
    end
  end
end
