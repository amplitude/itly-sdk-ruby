# frozen_string_literal: true

# Itly main class
class Itly
  include Itly::Plugins

  def initialize
    @plugins_instances = []
    @is_initialized = false
  end

  def load
    # Can call load only once
    raise InitializationError, 'Itly is already initialized.' if @is_initialized

    # Load options
    @options = Itly::Options.new
    yield @options if block_given?

    # Log
    logger.info 'Itly is disabled!' if disabled?
    logger.info 'load()'

    # Initialize plugins
    instantiate_plugins
    send_to_plugins :init, options: @options

    # Flag indicating that #load was called
    @is_initialized = true
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

  def validate(event:)
    return if validation_disabled?

    logger.info "validate(event: #{event})"

    send_to_plugins :validate, event: event
  end
end
