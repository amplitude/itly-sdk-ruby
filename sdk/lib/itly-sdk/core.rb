# frozen_string_literal: true

# Itly main class
class Itly
  include Itly::Plugins

  def initialize
    @plugins_instances = []

    # Load options
    @options = Itly::Options.new
    yield @options if block_given?

    # Log
    logger.info 'Itly is disabled!' if disabled?
    logger.info 'load()'

    # Initialize plugins
    instantiate_plugins
    send_to_plugins :init, options: @options
  end

  def alias(user_id:, previous_id:)
    return if disabled?

    logger.info "alias(user_id: #{user_id}, previous_id: #{previous_id})"

    send_to_plugins :alias, user_id: user_id, previous_id: previous_id
    send_to_plugins :post_alias, user_id: user_id, previous_id: previous_id
  end

  def flush
    return if disabled?

    logger.info 'flush()'

    send_to_plugins :flush
  end

  def reset
    return if disabled?

    logger.info 'reset()'

    send_to_plugins :reset
  end
end
