# frozen_string_literal: true

describe Itly::Plugin::Segment::CallOptions do
  describe 'instance attributes' do
    let(:options) { Itly::Plugin::Segment::CallOptions.new }

    it do
      %w[callback integrations context message_id timestamp anonymous_id].each do |prop|
        expect(options.respond_to?(prop)).to be(true)
        expect(options.respond_to?(:"#{prop}=")).to be(false)
      end
    end
  end

  describe '#initialize' do
    describe 'default values' do
      let(:options) { Itly::Plugin::Segment::CallOptions.new }

      it do
        %w[callback integrations context message_id timestamp anonymous_id].each do |prop|
          expect(options.send(prop)).to be(nil)
        end
      end
    end

    describe 'with values' do
      let(:callback) { ->(_a, _b) {} }
      let(:options) do
        Itly::Plugin::Segment::CallOptions.new(
          callback: callback, integrations: { 'integr' => true },
          context: { 'cont' => true }, message_id: 'MSGID', timestamp: '2021-05-01', anonymous_id: 'anID'
        )
      end

      it do
        expect(options.callback).to eq(callback)
        expect(options.integrations).to eq('integr' => true)
        expect(options.context).to eq('cont' => true)
        expect(options.message_id).to eq('MSGID')
        expect(options.timestamp).to eq('2021-05-01')
        expect(options.anonymous_id).to eq('anID')
      end
    end
  end

  describe 'to_hash' do
    describe 'without values' do
      let(:options) { Itly::Plugin::Segment::CallOptions.new }

      it do
        expect(options.to_hash).to eq({})
      end
    end

    describe 'with values' do
      let(:callback) { ->(_a, _b) {} }
      let(:options) do
        Itly::Plugin::Segment::CallOptions.new(
          callback: callback, integrations: { 'integr' => true },
          message_id: 'MSGID'
        )
      end

      it do
        expect(options.to_hash).to eq(integrations: { 'integr' => true }, message_id: 'MSGID')
      end
    end
  end

  describe 'to_s' do
    describe 'without values' do
      let(:options) { Itly::Plugin::Segment::CallOptions.new }

      it do
        expect(options.to_s).to eq('#<Segment::CallOptions callback: nil>')
      end
    end

    describe 'with values' do
      let(:callback) { ->(_a, _b) {} }
      let(:options) do
        Itly::Plugin::Segment::CallOptions.new(
          callback: callback, integrations: { 'integr' => true }, message_id: 'MSGID'
        )
      end

      it do
        expect(options.to_s).to eq(
          '#<Segment::CallOptions callback: provided integrations: {"integr"=>true} message_id: MSGID>'
        )
      end
    end
  end
end
