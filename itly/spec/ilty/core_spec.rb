# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
describe 'Itly' do
  describe 'module attributes' do
    it 'default values' do
      expect(Itly.is_initialized).to be(false)
    end

    it 'can read' do
      expect(Itly.respond_to?(:is_initialized)).to be(true)
    end

    it 'cannot write' do
      expect(Itly.respond_to?(:is_initialized=)).to be(false)
    end
  end

  describe '#load', :unload_itly do
    describe 'set @is_initialized to true' do
      before do
        Itly.load
      end

      it do
        expect(Itly.is_initialized).to be(true)
      end
    end

    it 'can be called only once' do
      expect { Itly.load }.not_to raise_error
      expect { Itly.load }.to raise_error(
        Itly::InitializationError, 'Itly is already initialized.'
      )
    end

    describe 'Initialize plugins' do
      context 'without registered plugin' do
        before do
          Itly.load
        end

        it do
          expect(Itly::Plugins.plugins_instances).to eq([])
        end
      end

      context 'when a plugin do not implement #load', fake_plugins: 1 do
        it do
          expect { Itly.load }.to raise_error(NotImplementedError)
        end
      end

      context 'with plugins', fake_plugins: 2, fake_plugins_methods: [:init] do
        before do
          expect_any_instance_of(FakePlugin0).to receive(:init)
          expect_any_instance_of(FakePlugin1).to receive(:init)
        end

        it do
          Itly.load

          expect(Itly::Plugins.plugins_instances.count).to eq(2)
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
