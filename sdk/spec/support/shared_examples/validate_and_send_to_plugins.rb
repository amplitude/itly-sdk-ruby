shared_examples 'validate and send to plugins' do |with_context: false, receive_action_methods: true, is_valid: true|
  let(:all_errors) { generates_context_errors + generates_event_errors }

  before do
    expect(itly).to receive(:validate_context_and_event).with(with_context, event)
      .and_return([generates_context_errors, generates_event_errors, is_valid])

    if receive_action_methods
      expect(plugin_a).to receive(:mock_action).with(event, :param)
      expect(plugin_b).to receive(:mock_action).with(event, :param)
    else
      expect(plugin_a).not_to receive(:mock_action)
      expect(plugin_b).not_to receive(:mock_action)
    end

    expect(itly).to receive(:log_validation_errors).with(all_errors, event)

    expect(plugin_a).to receive(:mock_post_action).with(event, all_errors, :other_param)
    expect(plugin_b).to receive(:mock_post_action).with(event, all_errors, :other_param)

    expect(itly).to receive(:raise_validation_errors).with(is_valid, all_errors, event)
  end
end
