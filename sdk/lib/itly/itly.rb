# frozen_string_literal: true

##
# Itly main class
#
class Itly
  include Itly::Plugins

  ##
  # Create a new Itly object.
  #
  # Initialize the instance variable +plugins_instances+ as an Array
  # so that it can contain instantiated plugins.
  # The +is_initialized+ instance variable is a True/False flag indicating
  # if the +load+ method was called on the object.
  #
  def initialize
    @plugins_instances = []
    @is_initialized = false
  end

  ##
  # Load options and initialize plugins. It can be called only once on an object.
  #
  # Accept an optional block to define the options. The variable yielded in
  # the block is an `Itly::Options`.
  #
  # All registered plugins will be instantiated and newly created objects
  # stored in the +plugins_instances+ instance variable.
  # After registration, the +load+ method of the plugins is called
  #  passing the +options+ object as an argument.
  #
  def load
    # Ensure #load was not already called on this object
    raise InitializationError, 'Itly is already initialized.' if @is_initialized

    # Create a new Options object and yield it is a block is provided
    @options = Itly::Options.new
    yield @options if block_given?

    # Log
    logger.info 'Itly is disabled!' if disabled?
    logger.info 'load()'

    # Initialize plugins, passing the options to their #load methods
    instantiate_plugins
    run_on_plugins lambda { |plugin|
      plugin.load options: @options
    }

    # Mark that the #load method was called on this object
    @is_initialized = true
  end

  ##
  # Identify a user in your application and associate all future events with
  # their identity, or to set their traits.
  #
  # Validates the +properties+ with all registered plugins first.
  # Raises a Itly::ValidationError if one of the validations failed and
  # if your set the +options.validation+ value to +ERROR_ON_INVALID+.
  #
  # Call +identify+ on all plugins and call +post_identify+ on all plugins.
  #
  # Example:
  #
  #     itly.identify user_id: 'MyUser123', role: 'admin'
  #
  # @param [String] user_id: the id of the user in your application
  # @param [Hash] properties: the user's traits to pass to your application
  #
  def identify(user_id:, properties:)
    # Run only if the object is not disabled
    return if disabled?

    # Log
    logger.info "identify(user_id: #{user_id}, properties: #{properties})"

    # Validate and run on all plugins
    event = Event.new name: 'identify', properties: properties

    validate_and_send_to_plugins event: event,
      action: lambda { |plugin, combined_event|
        plugin.identify user_id: user_id, properties: combined_event
      },
      post_action: lambda { |plugin, combined_event, validation_results|
        plugin.post_identify user_id: user_id, properties: combined_event, validation_results: validation_results
      }
  end

  ##
  # Asociate a user with their group (for example, their department or company),
  # or to set the group's traits.
  #
  # Validates the +properties+ with all registered plugins first.
  # Raises a Itly::ValidationError if one of the validations failed and
  # if your set the +options.validation+ value to +ERROR_ON_INVALID+.
  #
  # Call +group+ on all plugins and call +post_group+ on all plugins.
  #
  # Example:
  #
  #     itly.group user_id: 'MyUser123', group_id: 'MyGroup456', name: 'Iteratively, Inc.'
  #
  # @param [String] user_id: the id of the user in your application
  # @param [String] group_id: the id of the group in your application
  # @param [Hash] properties: The list of properties to pass to your application
  #
  def group(user_id:, group_id:, properties:)
    # Run only if the object is not disabled
    return if disabled?

    # Log
    logger.info "group(user_id: #{user_id}, group_id: #{group_id}, properties: #{properties})"

    # Validate and run on all plugins
    event = Event.new name: 'group', properties: properties

    validate_and_send_to_plugins event: event,
      action: lambda { |plugin, combined_event|
        plugin.group user_id: user_id, group_id: group_id, properties: combined_event
      },
      post_action: lambda { |plugin, combined_event, validation_results|
        plugin.post_group user_id: user_id, group_id: group_id,
          properties: combined_event, validation_results: validation_results
      }
  end

  ##
  # Track an event, call the event's corresponding function. Every event in
  # your tracking plan gets its own function in the Itly SDK.
  #
  # Validates the +properties+ of the +Event+ object passed as parameter
  # with all registered plugins first.
  # Raises a Itly::ValidationError if one of the validations failed and
  # if your set the +options.validation+ value to +ERROR_ON_INVALID+.
  #
  # The properties of the +options.context+ passed when created the +Itly+ object
  # are merged with the +event+ parameter before validation and calling the event
  # on your application.
  #
  # Call +track+ on all plugins and call +post_track+ on all plugins.
  #
  # Example:
  #
  #     itly.user_sign_in platform: 'web'
  #
  # @param [String] user_id: the id of the user in your application
  # @param [Event] event: the Event object to pass to your application
  #
  def track(user_id:, event:)
    # Run only if the object is not disabled
    return if disabled?

    # Log
    logger.info "track(user_id: #{user_id}, event: #{event.name}, properties: #{event.properties})"

    # Validate and run on all plugins
    validate_and_send_to_plugins event: event, include_context: true,
      action: lambda { |plugin, combined_event|
        plugin.track user_id: user_id, event: combined_event
      },
      post_action: lambda { |plugin, combined_event, validation_results|
        plugin.post_track user_id: user_id, event: combined_event, validation_results: validation_results
      }
  end

  ##
  # Associate one user ID with another (typically a known user ID with an anonymous one).
  #
  # Call +alias+ on all plugins and call +post_alias+ on all plugins.
  #
  # @param [String] user_id: The ID that the user will be identified by going forward. This is
  #   typically the user's database ID (as opposed to an anonymous ID), or their updated ID
  #   (for example, if the ID is an email address which the user just updated).
  # @param [String] previous_id: The ID the user has been identified by so far.
  #
  def alias(user_id:, previous_id:)
    # Run only if the object is not disabled
    return if disabled?

    # Log
    logger.info "alias(user_id: #{user_id}, previous_id: #{previous_id})"

    # Run on all plugins
    run_on_plugins lambda { |plugin|
      plugin.alias user_id: user_id, previous_id: previous_id
    }
    run_on_plugins lambda { |plugin|
      plugin.post_alias user_id: user_id, previous_id: previous_id
    }
  end

  ##
  # Send +flush+ to your plugins.
  #
  # Call +flush+ on all plugins.
  #
  def flush
    # Run only if the object is not disabled
    return if disabled?

    # Log
    logger.info 'flush()'

    # Run on all plugins
    run_on_plugins lambda { |plugin|
      plugin.flush
    }
  end

  ##
  # Reset the SDK's (and all plugins') state. This method is usually called when a user logs out.
  #
  # Call +reset+ on all plugins.
  #
  def reset
    # Run only if the object is not disabled
    return if disabled?

    # Log
    logger.info 'reset()'

    # Run on all plugins
    run_on_plugins lambda { |plugin|
      plugin.reset
    }
  end

  ##
  # Validate an Event
  #
  # Call +event+ on all plugins and collect their return values.
  #
  # @param [Event] event: the event to validate
  #
  # @return [Array] array of Itly::ValidationResponse objects that was generated by the plugins
  #
  def validate(event:)
    return if validation_disabled?

    # Log
    logger.info "validate(event: #{event})"

    # Run on all plugins
    run_on_plugins lambda { |plugin|
      plugin.validate event: event
    }
  end

  private

  def validate_and_send_to_plugins(action:, post_action:, event:, include_context: false)
    # Perform validation on the context and the event
    context_validations, event_validations, is_valid = validate_context_and_event include_context, event
    validations = context_validations + event_validations

    # Call the action on all plugins
    event.properties.merge! @options.context.properties if @options.context

    if is_valid || @options.validation == Itly::Options::Validation::TRACK_INVALID
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

    # Throw an exception if requested
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
    return unless !is_valid && @options.validation == Itly::Options::Validation::ERROR_ON_INVALID

    message = begin
      validations.reject(&:valid).first.message
    rescue StandardError
      "Unknown error validating #{event.name}"
    end
    raise ValidationError, message
  end
end