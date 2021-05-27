# frozen_string_literal: true

shared_examples 'validate and send to plugins' do |receive_action_methods: true, is_valid: true|
  let(:all_errors) { generates_context_errors + generates_event_errors }

  before do
    # Generate ValidationResponse objects when the Itly object if performing validation
    expect(itly).to receive(:validate_context_and_event).with(expected_context, event)
      .and_return([generates_context_errors, generates_event_errors, is_valid])

    # Set expectation for the targeted method call
    if receive_action_methods
      expect(plugin_a).to receive(:mock_action).with(event, :param)
      expect(plugin_b).to receive(:mock_action).with(event, :param)
    else
      expect(plugin_a).not_to receive(:mock_action)
      expect(plugin_b).not_to receive(:mock_action)
    end

    expect(plugin_c).not_to receive(:mock_action)

    # Set expectation for the targeted post method call
    expect(plugin_a).to receive(:mock_post_action).with(event, all_errors, :other_param)
    expect(plugin_b).to receive(:mock_post_action).with(event, all_errors, :other_param)

    expect(plugin_c).not_to receive(:mock_post_action)

    # Set expectation for log and exception triggered by validation responses
    expect(itly).to receive(:log_validation_errors).with(all_errors, event)

    expect(itly).to receive(:raise_validation_errors).with(is_valid, all_errors, event)
  end
end
