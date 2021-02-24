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
    run_on_plugins lambda { |plugin|
      plugin.init options: @options
    }

    # Flag indicating that #load was called
    @is_initialized = true
  end

  def alias(user_id:, previous_id:)
    return if disabled?

    logger.info "alias(user_id: #{user_id}, previous_id: #{previous_id})"

    run_on_plugins lambda { |plugin|
      plugin.alias user_id: user_id, previous_id: previous_id
    }
    run_on_plugins lambda { |plugin|
      plugin.post_alias user_id: user_id, previous_id: previous_id
    }
  end

  def flush
    return if disabled?

    logger.info 'flush()'

    run_on_plugins lambda { |plugin|
      plugin.flush
    }
  end

  def reset
    return if disabled?

    logger.info 'reset()'

    run_on_plugins lambda { |plugin|
      plugin.reset
    }
  end

  def validate(event:)
    return if validation_disabled?

    logger.info "validate(event: #{event})"

    run_on_plugins lambda { |plugin|
      plugin.validate event: event
    }
  end

  private

  def validate_and_send_to_plugins(action:, post_action:, event:, include_context:)
    # Perform validations
    context_validations, event_validations, is_valid = validate_context_and_event include_context, event
    validations = context_validations + event_validations

    # Call the action on all plugins
    event.properties.merge! @options.context.properties if @options.context

    if is_valid || @options.validation == Itly::ValidationOptions::TRACK_INVALID
      run_on_plugins lambda { |plugin|
        action.call(plugin, event)
      }
    end

    # Log all errors
    log_validation_errors validations, event

    # Call the post_action on all plugins
    run_on_plugins lambda { |plugin|
      post_action.call(plugin, event, validations)
    }

    # Throw exception if requested
    raise_validation_errors is_valid, validations, event
  end

  def validate_context_and_event(include_context, event)
    # Validate the context
    context_validations = (validate event: @options.context if include_context && @options.context) || []

    # Validate the event
    event_validations = validate(event: event) || []

    # Check if all validation succedded
    is_valid = context_validations.all?(&:valid) && event_validations.all?(&:valid)

    [context_validations, event_validations, is_valid]
  end

  def log_validation_errors(validations, event)
    validations.reject(&:valid).each do |response|
      @options.logger.error "Validation error for #{event.name}: #{response.message}"
    end
  end

  def raise_validation_errors(is_valid, validations, event)
    return unless !is_valid && @options.validation == Itly::ValidationOptions::ERROR_ON_INVALID

    message = begin
      validations.reject(&:valid).first.message
    rescue StandardError
      "Unknown error validating #{event.name}"
    end
    raise ValidationError, message
  end
end
