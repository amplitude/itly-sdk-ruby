# frozen_string_literal: true

describe Itly::Plugin::Iteratively::Client do
  include RspecLoggerHelpers

  let(:client_default_values) do
    {
      url: 'http://url/path', api_key: 'key123',
      logger: nil, flush_queue_size: 1, batch_size: 5, flush_interval_ms: 6, max_retries: 2, retry_delay_min: 3.0,
      retry_delay_max: 4.0, omit_values: false, branch: 'feature/new', version: '1.2.3'
    }
  end

  describe 'instance attributes' do
    let(:client) { Itly::Plugin::Iteratively::Client.new(**client_default_values) }

    it 'can read' do
      %i[api_key url logger flush_queue_size batch_size flush_interval_ms max_retries retry_delay_min
         retry_delay_max omit_values branch version].each do |attribute|
        expect(client.respond_to?(attribute)).to be(true)
      end
    end

    it 'cannot write' do
      %i[api_key url logger flush_queue_size batch_size flush_interval_ms max_retries retry_delay_min
         retry_delay_max omit_values branch version].each do |attribute|
        expect(client.respond_to?(:"#{attribute}=")).to be(false)
      end
    end
  end

  describe '#initialize' do
    let(:logger) { ::Logger.new '/dev/null' }
    let(:client) { Itly::Plugin::Iteratively::Client.new(**client_default_values.merge(logger: logger)) }

    it 'instance variables' do
      expect(client.instance_variable_get('@buffer')).to be_a_kind_of(Concurrent::Array)
      expect(client.instance_variable_get('@buffer')).to eq([])
      expect(client.instance_variable_get('@runner')).to be(nil)
      expect(client.instance_variable_get('@scheduler')).to be(nil)
      expect(client.instance_variable_get('@url')).to eq('http://url/path')
      expect(client.instance_variable_get('@api_key')).to eq('key123')
      expect(client.instance_variable_get('@logger')).to eq(logger)
      expect(client.instance_variable_get('@flush_queue_size')).to eq(1)
      expect(client.instance_variable_get('@batch_size')).to eq(5)
      expect(client.instance_variable_get('@flush_interval_ms')).to eq(6)
      expect(client.instance_variable_get('@max_retries')).to eq(2)
      expect(client.instance_variable_get('@retry_delay_min')).to eq(3.0)
      expect(client.instance_variable_get('@retry_delay_max')).to eq(4.0)
      expect(client.instance_variable_get('@omit_values')).to be(false)
      expect(client.instance_variable_get('@branch')).to eq('feature/new')
      expect(client.instance_variable_get('@version')).to eq('1.2.3')
    end

    describe 'start scheduler' do
      before do
        expect_any_instance_of(Itly::Plugin::Iteratively::Client).to receive(:start_scheduler)
      end

      it do
        client
      end
    end
  end

  describe '#track' do
    let(:event1) { Itly::Event.new name: 'event1', properties: { some: 'data' } }
    let(:event2) { Itly::Event.new name: 'event2', properties: { some: 'data' } }
    let(:validation1) { Itly::ValidationResponse.new valid: true, plugin_id: 'id1', message: 'Msg1' }
    let(:validation2) { Itly::ValidationResponse.new valid: false, plugin_id: 'id2', message: 'Msg2' }

    let(:client) { Itly::Plugin::Iteratively::Client.new(**client_default_values.merge(flush_queue_size: 2)) }

    describe 'enqueue models' do
      before do
        allow(Time).to receive(:now).and_return(Time.parse('2021-01-01T06:00:00Z'))

        allow(client).to receive(:flush)

        client.track type: 'test_model', event: event1, properties: nil, validation: validation1
        client.track type: 'test_model', event: event2, properties: nil, validation: nil
        client.track type: 'test_model', event: nil, properties: { other: 'info' }, validation: validation2
      end

      let(:buffer) { client.instance_variable_get '@buffer' }

      let(:expected) do
        [
          '#<Itly::Plugin::Iteratively::TrackModel: type: test_model date_sent: 2021-01-01T06:00:00Z event_id:  '\
            'event_schema_version:  event_name: event1 properties: {:some=>"data"} '\
            'valid: true validation: {:details=>"Msg1"}>',
          '#<Itly::Plugin::Iteratively::TrackModel: type: test_model date_sent: 2021-01-01T06:00:00Z event_id:  '\
            'event_schema_version:  event_name: event2 properties: {:some=>"data"} '\
            'valid: true validation: {:details=>""}>',
          '#<Itly::Plugin::Iteratively::TrackModel: type: test_model date_sent: 2021-01-01T06:00:00Z event_id:  '\
            'event_schema_version:  event_name:  properties: {:other=>"info"} '\
            'valid: false validation: {:details=>"Msg2"}>'
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
        client.track type: 'test_model', event: event1, properties: nil, validation: nil
      end
    end

    describe 'reach buffer size' do
      before do
        expect(client).to receive(:flush).once
      end

      it do
        client.track type: 'test_model', event: event1, properties: nil, validation: nil
        client.track type: 'test_model', event: event1, properties: nil, validation: nil
      end
    end

    describe 'reach above buffer size' do
      before do
        expect(client).to receive(:flush).twice
      end

      it do
        client.track type: 'test_model', event: event1, properties: nil, validation: nil
        client.track type: 'test_model', event: event1, properties: nil, validation: nil
        client.track type: 'test_model', event: event1, properties: nil, validation: nil
      end
    end
  end

  describe '#flush' do
    let(:event1) { Itly::Event.new name: 'event1', properties: { some: 'data' } }
    let(:event2) { Itly::Event.new name: 'event2', properties: { some: 'data' } }
    let(:event3) { Itly::Event.new name: 'event3', properties: { some: 'data' } }
    let(:model1) do
      Itly::Plugin::Iteratively::TrackModel.new omit_values: false, type: 'model1', event: event1, properties: nil
    end
    let(:model2) do
      Itly::Plugin::Iteratively::TrackModel.new omit_values: false, type: 'model2', event: event2, properties: nil
    end
    let(:model3) do
      Itly::Plugin::Iteratively::TrackModel.new omit_values: false, type: 'model3', event: event3, properties: nil
    end

    let(:logs) { StringIO.new }
    let(:logger) { ::Logger.new logs }
    let(:batch_size) { 5 }
    let(:client) do
      Itly::Plugin::Iteratively::Client.new(**client_default_values.merge(logger: logger, batch_size: batch_size))
    end

    let(:buffer) { client.instance_variable_get '@buffer' }
    let(:runner) { client.instance_variable_get '@runner' }

    context 'default' do
      before do
        buffer << model1 << model2 << model3

        expect(client).to receive(:post_models).once.with([model1, model2, model3]).and_return(true)
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

    context 'send by batch' do
      let(:batch_size) { 2 }

      before do
        buffer << model1 << model2 << model3

        expect(client).to receive(:post_models).once.with([model1, model2]).and_return(true)
        expect(client).to receive(:post_models).once.with([model3]).and_return(true)
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
        buffer << model1 << model2 << model3

        expect(client).to receive(:post_models).once.with([model1, model2, model3]).and_return(false)
        expect(client).to receive(:post_models).once.with([model1, model2, model3]).and_return(true)
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

    context 'retry by batch' do
      let(:batch_size) { 2 }

      before do
        buffer << model1 << model2 << model3

        expect(client).to receive(:post_models).once.with([model1, model2]).and_return(false)
        expect(client).to receive(:post_models).once.with([model1, model2]).and_return(true)
        expect(client).to receive(:post_models).once.with([model3]).and_return(false)
        expect(client).to receive(:post_models).once.with([model3]).and_return(true)
        expect(client).not_to receive(:post_models)

        expect(client).to receive(:sleep).twice.with(3.0)
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
        buffer << model1 << model2 << model3

        expect(client).to receive(:post_models).once.with([model1, model2, model3]).and_return(false)
        expect(client).to receive(:post_models).once.with([model1, model2, model3]).and_return(false)
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
           'Iteratively::Client: flush() reached maximum number of tries. 3 events won\'t be sent to the server']
        ]

        expect(buffer).to eq([])
      end
    end
  end

  describe '#shutdown' do
    let(:client) { Itly::Plugin::Iteratively::Client.new(**client_default_values) }

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
    let(:client) { Itly::Plugin::Iteratively::Client.new(**client_default_values.merge(flush_queue_size: 2)) }

    before do
      allow(client).to receive(:flush)
    end

    context 'less than max' do
      before do
        client.track type: 'test_model', event: event, properties: nil, validation: nil
      end

      it do
        expect(client.send(:buffer_full?)).to be(false)
      end
    end

    context 'equal to max' do
      before do
        client.track type: 'test_model', event: event, properties: nil, validation: nil
        client.track type: 'test_model', event: event, properties: nil, validation: nil
      end

      it do
        expect(client.send(:buffer_full?)).to be(true)
      end
    end

    context 'more than max' do
      before do
        client.track type: 'test_model', event: event, properties: nil, validation: nil
        client.track type: 'test_model', event: event, properties: nil, validation: nil
        client.track type: 'test_model', event: event, properties: nil, validation: nil
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
      Itly::Plugin::Iteratively::TrackModel.new(
        omit_values: false, type: 'test_model', event: event, properties: nil, validation: validation
      )
    end

    let(:logs) { StringIO.new }
    let(:logger) { ::Logger.new logs }
    let(:client) { Itly::Plugin::Iteratively::Client.new(**client_default_values.merge(logger: logger)) }

    let(:expected_model_json) do
      {
        'branchName' => 'feature/new',
        'trackingPlanVersion' => '1.2.3',
        'objects' => [
          {
            'type' => 'test_model',
            'dateSent' => '2021-01-01T06:00:00Z',
            'eventId' => 'id123',
            'eventSchemaVersion' => '12',
            'eventName' => 'test_event',
            'properties' => { 'data' => 'value' },
            'valid' => false,
            'validation' => { 'details' => 'Validation Msg' }
          }
        ]
      }.to_json
    end

    let(:expected_headers) do
      {
        'Content-Type' => 'application/json',
        'authorization' => 'Bearer key123'
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
        expect(Faraday).to receive(:post)
          .with(
            'http://url/path',
            expected_model_json,
            expected_headers
          )
          .and_return(response)
      end

      let(:expected_log) do
        'Iteratively::Client: post_models() unexpected response. Url: http://url/path '\
          'Data: {'\
            '"branchName":"feature/new",'\
            '"trackingPlanVersion":"1.2.3",'\
            '"objects":[{"type":"test_model","dateSent":"2021-01-01T06:00:00Z","eventId":"id123",'\
              '"eventSchemaVersion":"12","eventName":"test_event","properties":{"data":"value"},"valid":false,'\
              '"validation":{"details":"Validation Msg"}}]'\
            '} '\
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
    let(:client) { Itly::Plugin::Iteratively::Client.new(**client_default_values) }

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
      Itly::Plugin::Iteratively::Client.new(
        **client_default_values.merge(retry_delay_min: 10.0, retry_delay_max: 3600.0, max_retries: 25)
      )
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

  describe 'start_scheduler' do
    let(:client) { Itly::Plugin::Iteratively::Client.new(**client_default_values) }

    before do
      # Start
      expect(client).to receive(:start_scheduler).once.and_call_original

      # First run
      expect(client).to receive(:runner_complete?).once.and_return(true)
      expect(client).to receive(:flush).once
      expect(client).to receive(:start_scheduler).once.and_call_original

      # Second run
      expect(client).to receive(:runner_complete?).once.and_return(false)
      expect(client).not_to receive(:flush)
      expect(client).to receive(:start_scheduler).once # We don't call original, so we break the chain

      expect(client).not_to receive(:start_scheduler)
    end

    it do
      # Start
      client.send :start_scheduler

      # First run
      scheduler1 = client.instance_variable_get '@scheduler'
      scheduler1.reschedule 0.1
      scheduler1.wait

      # Second run
      scheduler2 = client.instance_variable_get '@scheduler'
      expect(scheduler1.object_id).not_to eq(scheduler2.object_id)
      scheduler2.reschedule 0.1
      scheduler2.wait
    end
  end
end
