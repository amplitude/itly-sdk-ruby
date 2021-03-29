# frozen_string_literal: true

describe Itly::Plugin::Iteratively::Client do
  include RspecLoggerHelpers

  describe 'instance attributes' do
    let(:client) do
      Itly::Plugin::Iteratively::Client.new \
        url: 'http://url', api_key: 'key123',
        logger: nil, buffer_size: 1, max_retries: 2, retry_delay_min: 3.0,
        retry_delay_max: 4.0, omit_values: false
    end

    it 'can read' do
      %i[api_key url logger buffer_size max_retries retry_delay_min retry_delay_max omit_values].each do |attribute|
        expect(client.respond_to?(attribute)).to be(true)
      end
    end

    it 'cannot write' do
      %i[api_key url logger buffer_size max_retries retry_delay_min retry_delay_max omit_values].each do |attribute|
        expect(client.respond_to?(:"#{attribute}=")).to be(false)
      end
    end
  end

  describe '#initialize' do
    let(:logger) { ::Logger.new '/dev/null' }
    let(:client) do
      Itly::Plugin::Iteratively::Client.new \
        url: 'http://url', api_key: 'key123',
        logger: logger, buffer_size: 1, max_retries: 2, retry_delay_min: 3.0,
        retry_delay_max: 4.0, omit_values: false
    end

    it do
      expect(client.instance_variable_get('@buffer')).to be_a_kind_of(Concurrent::Array)
      expect(client.instance_variable_get('@buffer')).to eq([])
      expect(client.instance_variable_get('@buffrunnerr')).to be(nil)
      expect(client.instance_variable_get('@url')).to eq('http://url')
      expect(client.instance_variable_get('@api_key')).to eq('key123')
      expect(client.instance_variable_get('@logger')).to eq(logger)
      expect(client.instance_variable_get('@buffer_size')).to eq(1)
      expect(client.instance_variable_get('@max_retries')).to eq(2)
      expect(client.instance_variable_get('@retry_delay_min')).to eq(3.0)
      expect(client.instance_variable_get('@retry_delay_max')).to eq(4.0)
      expect(client.instance_variable_get('@omit_values')).to be(false)
    end
  end

  describe '#track' do
    let(:event1) { Itly::Event.new name: 'event1', properties: { some: 'data' } }
    let(:event2) { Itly::Event.new name: 'event2', properties: { some: 'data' } }
    let(:event3) { Itly::Event.new name: 'event3', properties: { some: 'data' } }
    let(:validation1) { Itly::ValidationResponse.new valid: true, plugin_id: 'id1', message: 'Msg1' }
    let(:validation2) { Itly::ValidationResponse.new valid: false, plugin_id: 'id2', message: 'Msg2' }

    let(:client) do
      Itly::Plugin::Iteratively::Client.new \
        url: 'http://url', api_key: 'key123',
        logger: nil, buffer_size: 2, max_retries: 2, retry_delay_min: 3.0,
        retry_delay_max: 4.0, omit_values: false
    end

    describe 'enqueue models' do
      before do
        allow(Time).to receive(:now).and_return(Time.parse('2021-01-01T06:00:00Z'))

        allow(client).to receive(:flush)

        client.track type: 'test_model', event: event1, validation: validation1
        client.track type: 'test_model', event: event2, validation: nil
        client.track type: 'test_model', event: event3, validation: validation2
      end

      let(:buffer) { client.instance_variable_get '@buffer' }

      let(:expected) do
        [
          '#<Itly::Plugin::Iteratively::Model: type: test_model date_sent: 2021-01-01T06:00:00Z event_id:  '\
            'event_chema_version:  event_name: event1 properties: {:some=>"data"} valid: true validation: Msg1>',
          '#<Itly::Plugin::Iteratively::Model: type: test_model date_sent: 2021-01-01T06:00:00Z event_id:  '\
            'event_chema_version:  event_name: event2 properties: {:some=>"data"} valid:  validation: >',
          '#<Itly::Plugin::Iteratively::Model: type: test_model date_sent: 2021-01-01T06:00:00Z event_id:  '\
            'event_chema_version:  event_name: event3 properties: {:some=>"data"} valid: false validation: Msg2>'
        ]
      end

      it do
        expect(buffer.length).to eq(3)
        expect(buffer.collect(&:to_s)).to eq(expected)
      end
    end

    describe 'do not reach buffer size' do
      before do
        expect(client).not_to receive(:flush)
      end

      it do
        client.track type: 'test_model', event: event1, validation: nil
      end
    end

    describe 'reach buffer size' do
      before do
        expect(client).to receive(:flush).once
      end

      it do
        client.track type: 'test_model', event: event1, validation: nil
        client.track type: 'test_model', event: event1, validation: nil
      end
    end

    describe 'reach above buffer size' do
      before do
        expect(client).to receive(:flush).twice
      end

      it do
        client.track type: 'test_model', event: event1, validation: nil
        client.track type: 'test_model', event: event1, validation: nil
        client.track type: 'test_model', event: event1, validation: nil
      end
    end
  end

  describe '#flush' do
    let(:event1) { Itly::Event.new name: 'event1', properties: { some: 'data' } }
    let(:event2) { Itly::Event.new name: 'event2', properties: { some: 'data' } }
    let(:model1) { Itly::Plugin::Iteratively::Model.new omit_values: false, type: 'model1', event: event1 }
    let(:model2) { Itly::Plugin::Iteratively::Model.new omit_values: false, type: 'model2', event: event2 }

    let(:logs) { StringIO.new }
    let(:logger) { ::Logger.new logs }
    let(:client) do
      Itly::Plugin::Iteratively::Client.new \
        url: 'http://url', api_key: 'key123',
        logger: logger, buffer_size: 2, max_retries: 2, retry_delay_min: 3.0,
        retry_delay_max: 4.0, omit_values: false
    end

    let(:buffer) { client.instance_variable_get '@buffer' }
    let(:runner) { client.instance_variable_get '@runner' }

    context 'default' do
      before do
        buffer << model1 << model2

        expect(client).to receive(:post_models).once.with([model1, model2]).and_return(true)
        expect(client).not_to receive(:post_models)

        expect(Kernel).not_to receive(:sleep)
      end

      it do
        # Run and wait for Threads to complete, or timeout after 3 seconds
        client.send :flush
        runner.wait_or_cancel(3)

        expect_log_lines_to_equal []

        expect(buffer).to eq([])
      end
    end

    context 'empty buffer' do
      before do
        expect(client).not_to receive(:post_models)
        expect(Kernel).not_to receive(:sleep)
      end

      it do
        client.send :flush

        expect(runner).to be(nil)
        expect_log_lines_to_equal []
      end
    end

    context 'retry' do
      before do
        buffer << model1 << model2

        expect(client).to receive(:post_models).once.with([model1, model2]).and_return(false)
        expect(client).to receive(:post_models).once.with([model1, model2]).and_return(true)
        expect(client).not_to receive(:post_models)

        expect(client).to receive(:sleep).once.with(3.0)
        expect(client).not_to receive(:sleep)
      end

      it do
        # Run and wait for Threads to complete, or timeout after 3 seconds
        client.send :flush
        runner.wait_or_cancel(3)

        expect_log_lines_to_equal []

        expect(buffer).to eq([])
      end
    end

    context 'reach maximum nbr of retries' do
      before do
        buffer << model1 << model2

        expect(client).to receive(:post_models).once.with([model1, model2]).and_return(false)
        expect(client).to receive(:post_models).once.with([model1, model2]).and_return(false)
        expect(client).not_to receive(:post_models)

        expect(client).to receive(:sleep).once.with(3.0)
        expect(client).not_to receive(:sleep)
      end

      it do
        # Run and wait for Threads to complete, or timeout after 3 seconds
        client.send :flush
        runner.wait_or_cancel(3)

        expect_log_lines_to_equal [
          ['error',
           'Iteratively::Client: flush() reached maximun number of tries. 2 events won\'t be sent to the server']
        ]

        expect(buffer).to eq([])
      end
    end
  end

  describe '#shutdown' do
    let(:client) do
      Itly::Plugin::Iteratively::Client.new \
        url: 'http://url', api_key: 'key123',
        logger: nil, buffer_size: 2, max_retries: 2, retry_delay_min: 3.0,
        retry_delay_max: 4.0, omit_values: false
    end

    describe 'default' do
      before do
        expect(client).to receive(:flush)
      end

      context 'no runner' do
        it do
          client.shutdown

          expect(client.instance_variable_get('@max_retries')).to eq(0)
          expect(client.instance_variable_get('@runner')).to be(nil)
        end
      end

      context 'with a runner' do
        let(:runner) { double 'runner', wait_or_cancel: nil }

        before do
          client.instance_variable_set '@runner', runner
          expect(runner).to receive(:wait_or_cancel).with(3.0)
        end

        it do
          client.shutdown

          expect(client.instance_variable_get('@max_retries')).to eq(0)
        end
      end
    end

    describe 'force' do
      before do
        expect(client).not_to receive(:flush)
      end

      context 'no runner' do
        it do
          client.shutdown force: true

          expect(client.instance_variable_get('@max_retries')).to eq(2)
        end
      end

      context 'with a runner' do
        let(:runner) { double 'runner', wait_or_cancel: nil }

        before do
          client.instance_variable_set '@runner', runner
          expect(runner).to receive(:cancel)
        end

        it do
          client.shutdown force: true

          expect(client.instance_variable_get('@max_retries')).to eq(2)
        end
      end
    end
  end

  describe '#buffer_full?' do
    let(:event) { Itly::Event.new name: 'event', properties: { some: 'data' } }
    let(:client) do
      Itly::Plugin::Iteratively::Client.new \
        url: 'http://url', api_key: 'key123',
        logger: nil, buffer_size: 2, max_retries: 2, retry_delay_min: 3.0,
        retry_delay_max: 4.0, omit_values: false
    end

    before do
      allow(client).to receive(:flush)
    end

    context 'less than max' do
      before do
        client.track type: 'test_model', event: event, validation: nil
      end

      it do
        expect(client.send(:buffer_full?)).to be(false)
      end
    end

    context 'equal to max' do
      before do
        client.track type: 'test_model', event: event, validation: nil
        client.track type: 'test_model', event: event, validation: nil
      end

      it do
        expect(client.send(:buffer_full?)).to be(true)
      end
    end

    context 'more than max' do
      before do
        client.track type: 'test_model', event: event, validation: nil
        client.track type: 'test_model', event: event, validation: nil
        client.track type: 'test_model', event: event, validation: nil
      end

      it do
        expect(client.send(:buffer_full?)).to be(true)
      end
    end
  end

  describe '#post_models' do
    let(:event) { Itly::Event.new name: 'test_event', id: 'id123', version: '12', properties: { data: 'value' } }
    let(:validation) { Itly::ValidationResponse.new valid: false, plugin_id: 'id', message: 'Validation Msg' }
    let(:model) do
      Itly::Plugin::Iteratively::Model.new omit_values: false, type: 'test_model', event: event, validation: validation
    end

    let(:logs) { StringIO.new }
    let(:logger) { ::Logger.new logs }
    let(:client) do
      Itly::Plugin::Iteratively::Client.new \
        url: 'http://url/path', api_key: 'api_key123',
        logger: logger, buffer_size: 1, max_retries: 2, retry_delay_min: 3.0,
        retry_delay_max: 4.0, omit_values: false
    end

    let(:expected_model_json) do
      '{"objects":[{"type":"test_model","dateSent":"2021-01-01T06:00:00Z","eventId":"id123","eventChemaVersion":"12",'\
       '"eventName":"test_event","properties":{"data":"value"},"valid":false,"validation":"Validation Msg"}]}'
    end

    let(:expected_headers) do
      {
        'Content-Type' => 'application/json',
        'authorization' => 'Bearer api_key123'
      }
    end

    before do
      allow(Time).to receive(:now).and_return(Time.parse('2021-01-01T06:00:00Z'))
    end

    context 'success' do
      let(:response) { double 'response', status: 201 }

      before do
        expect(Faraday).to receive(:post).with('http://url/path', expected_model_json, expected_headers)
          .and_return(response)
      end

      it do
        expect(client.send(:post_models, [model])).to be(true)

        expect_log_lines_to_equal []
      end
    end

    context 'failure' do
      let(:response) do
        double 'response', status: 400, headers: { 'server' => 'nginx' }, body: 'error description'
      end

      before do
        expect(Faraday).to receive(:post).with('http://url/path', expected_model_json, expected_headers)
          .and_return(response)
      end

      let(:expected_log) do
        'Iteratively::Client: post_models() unexpected response. Url: http://url/path '\
          'Data: {"objects":[{"type":"test_model","dateSent":"2021-01-01T06:00:00Z","eventId":"id123",'\
            '"eventChemaVersion":"12","eventName":"test_event","properties":{"data":"value"},"valid":false,'\
            '"validation":"Validation Msg"}]} '\
          'Response status: 400 Response headers: {"server"=>"nginx"} '\
          'Response body: error description'
      end

      it do
        expect(client.send(:post_models, [model])).to be(false)

        expect_log_lines_to_equal [
          ['error', expected_log]
        ]
      end
    end

    context 'exception' do
      let(:response) do
        double 'response', status: 400, headers: { 'server' => 'nginx' }, body: 'error description'
      end

      before do
        expect(Faraday).to receive(:post).with('http://url/path', expected_model_json, expected_headers)
          .and_raise('Test exception')
      end

      it do
        expect(client.send(:post_models, [model])).to be(false)

        expect_log_lines_to_equal [
          ['error', 'Iteratively::Client: post_models() exception RuntimeError: Test exception']
        ]
      end
    end
  end

  describe '#runner_complete?' do
    let(:client) do
      Itly::Plugin::Iteratively::Client.new \
        url: 'http://url', api_key: 'key123',
        logger: nil, buffer_size: 2, max_retries: 2, retry_delay_min: 3.0,
        retry_delay_max: 4.0, omit_values: false
    end

    before do
      client.instance_variable_set '@runner', runner
    end

    context 'runner is not initialized' do
      let(:runner) { nil }

      it do
        expect(client.send(:runner_complete?)).to be(true)
      end
    end

    context 'runner is running' do
      let(:runner) { double 'runner', complete?: false }

      it do
        expect(client.send(:runner_complete?)).to be(false)
      end
    end

    context 'runner is complete' do
      let(:runner) { double 'runner', complete?: true }

      it do
        expect(client.send(:runner_complete?)).to be(true)
      end
    end
  end

  describe '#delay_before_next_try' do
    let(:client) do
      Itly::Plugin::Iteratively::Client.new \
        url: 'http://url', api_key: 'key123',
        logger: nil, buffer_size: 2, max_retries: 25, retry_delay_min: 10.0,
        retry_delay_max: 3600.0, omit_values: false
    end

    it 'min' do
      expect(client.send(:delay_before_next_try, 1)).to be_within(0.1).of(10.0)
    end

    it 'max' do
      expect(client.send(:delay_before_next_try, 25)).to be_within(0.1).of(3600.0)
    end

    # This shows the delay in second between each retry in sequence
    describe 'steps' do
      let(:steps) { 25.times.collect { |i| client.send(:delay_before_next_try, i + 1).round } }
      let(:expected) do
        [
          10, 18, 41, 79, 132, 201, 283, 380, 491, 615, 752, 901, 1061, 1233, 1415, 1606,
          1805, 2012, 2226, 2446, 2671, 2900, 3131, 3365, 3600
        ]
      end

      it do
        expect(steps).to eq(expected)
      end
    end
  end
end
