# frozen_string_literal: true

module RspecItlyHelpers
  # rubocop:disable Metrics/AbcSize
  def expect_to_receive_message_with_event(object, message, name:, call_original: true)
    expect(object).to receive(message).once.and_wrap_original do |m, *args|
      expect(args.count).to eq(1)
      expect(args[0].keys).to eq([:event])
      expect(args[0][:event].name).to eq(name)
      m.call(*args) if call_original
    end
  end
  # rubocop:enable Metrics/AbcSize
end
