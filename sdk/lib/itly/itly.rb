# frozen_string_literal: true

##
# Itly main class
#
class Itly
  include Itly::Plugins

  ##
  # Create a new Itly object.
  #
  # The +is_initialized+ instance variable is a True/False flag indicating
  # if the +load+ method was called on the object.
  #
  def initialize
    @is_initialized = false
  end

  ##
  # Load options ans the plugins. It must be called only once on an object.
  #
  # Accept an optional block to define the options. The variable yielded in
  # the block is of type `Itly::Options`.
  #
  # Calls the +load+ method of each plugin passing the +options+ object as an argument.
  #
  # @param [Hash, nil] context: to assign to the "context" Event object. Default to nil
  #
  def load(context: nil)
    # Ensure #load was not already called on this object
    raise InitializationError, 'Itly is already initialized.' if @is_initialized

    # Create a new Options object and yield it is a block is provided
    @options = Itly::Options.new
    yield @options if block_given?

    # Create the context event
    @context = context.nil? ? nil : Itly::Event.new(name: 'context', properties: context)

    # Log
    logger&.info 'load()'
    logger&.info 'Itly is disabled!' unless enabled?
    logger&.warn 'No plugin enabled!' if options.plugins.empty?

    # pass options to plugins
    run_on_plugins { |plugin| plugin.load options: options.for_plugin } if enabled?

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
  # @param [Hash] options: plugin specific option. The keys must correspond
  #   to a plugin id, and the values will be passed only to the plugin identified by the key.
  #
  def identify(user_id:, properties: {}, options: {})
    # Run only if the object is enabled and was initialized
    return unless was_initialized? && enabled?

    # Log
    log = Itly::Loggers.vars_to_log user_id: user_id, properties: properties, options: options
    logger&.info "identify(#{log})"

    # Validate and run on all plugins
    event = Event.new name: 'identify', properties: properties

    action = ->(plugin, combined_event) {
      plugin.identify(
        user_id: user_id, properties: combined_event.properties, options: options[plugin.id]
      )
    }

    post_action = ->(plugin, combined_event, validation_results) {
      plugin.post_identify(
        user_id: user_id, properties: combined_event.properties, validation_results: validation_results
      )
    }

    validate_and_send_to_plugins event: event, action: action, post_action: post_action
  end

  ##
  # Associate a user with their group (for example, their department or company),
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
  # @param [Hash] options: plugin specific option. The keys must correspond
  #   to a plugin id, and the values will be passed only to the plugin identified by the key.
  #
  def group(user_id:, group_id:, properties: {}, options: {})
    # Run only if the object is enabled and was initialized
    return unless was_initialized? && enabled?

    # Log
    log = Itly::Loggers.vars_to_log user_id: user_id, group_id: group_id, properties: properties, options: options
    logger&.info "group(#{log})"

    # Validate and run on all plugins
    event = Event.new name: 'group', properties: properties

    action = ->(plugin, combined_event) {
      plugin.group(
        user_id: user_id, group_id: group_id, properties: combined_event.properties,
        options: options[plugin.id]
      )
    }

    post_action = ->(plugin, combined_event, validation_results) {
      plugin.post_group(
        user_id: user_id, group_id: group_id, properties: combined_event.properties,
        validation_results: validation_results
      )
    }

    validate_and_send_to_plugins event: event, action: action, post_action: post_action
  end

  ##
  # The Page method lets you record page views, along with optional extra information about
  # the page viewed by the user.
  #
  # Validates the +properties+ with all registered plugins first.
  # Raises a Itly::ValidationError if one of the validations failed and
  # if your set the +options.validation+ value to +ERROR_ON_INVALID+.
  #
  # Call +page+ on all plugins and call +post_page+ on all plugins.
  #
  # Example:
  #
  #     itly.page user_id: 'MyUser123', category: 'Products', name: 'MyPage456', name: 'Iteratively, Inc.'
  #
  # @param [String] user_id: the id of the user in your application
  # @param [String] category: the category of the page
  # @param [String] name: the name of the page.
  # @param [Hash] properties: The list of properties to pass to your application
  # @param [Hash] options: plugin specific option. The keys must correspond
  #   to a plugin id, and the values will be passed only to the plugin identified by the key.
  #
  def page(user_id:, category: nil, name: nil, properties: {}, options: {})
    # Run only if the object is enabled and was initialized
    return unless was_initialized? && enabled?

    # Log
    log = Itly::Loggers.vars_to_log(
      user_id: user_id, category: category, name: name, properties: properties, options: options
    )
    logger&.info "page(#{log})"

    # Validate and run on all plugins
    event = Event.new name: 'page', properties: properties

    action = ->(plugin, combined_event) {
      plugin.page(
        user_id: user_id, category: category, name: name, properties: combined_event.properties,
        options: options[plugin.id]
      )
    }

    post_action = ->(plugin, combined_event, validation_results) {
      plugin.post_page(
        user_id: user_id, category: category, name: name, properties: combined_event.properties,
        validation_results: validation_results
      )
    }

    validate_and_send_to_plugins event: event, action: action, post_action: post_action
  end

  ##
  # Track an event, call the event's corresponding function on plugins.
  #
  # Validates the +properties+ of the +Event+ object passed as parameter
  # with all registered plugins first.
  # Raises a Itly::ValidationError if one of the validations failed and
  # if your set the +options.validation+ value to +ERROR_ON_INVALID+.
  #
  # The properties of the +context+ instance attribute passed when called #load
  # are merged with the +event+ parameter before validation and calling the event
  # on your application.
  #
  # Call +track+ on all plugins and call +post_track+ on all plugins.
  #
  # Example:
  #
  #     event = Itly::Event.new name: 'watched_video', properties: {'video_id' => 'MyVider123', watch_time: '123456'}
  #     itly.track user_id: 'MyUser123', event: event
  #
  # @param [String] user_id: the id of the user in your application
  # @param [Event] event: the Event object to pass to your application
  # @param [Hash] options: plugin specific option. The keys must correspond
  #   to a plugin id, and the values will be passed only to the plugin identified by the key.
  #
  def track(user_id:, event:, options: {})
    # Run only if the object is enabled and was initialized
    return unless was_initialized? && enabled?

    # Log
    log = Itly::Loggers.vars_to_log(
      user_id: user_id, event: event&.name, properties: event&.properties, options: options
    )
    logger&.info "track(#{log})"

    # Validate and run on all plugins
    action = ->(plugin, combined_event) {
      plugin.track user_id: user_id, event: combined_event, options: options[plugin.id]
    }

    post_action = ->(plugin, combined_event, validation_results) {
      plugin.post_track user_id: user_id, event: combined_event, validation_results: validation_results
    }

    validate_and_send_to_plugins event: event, context: @context, action: action, post_action: post_action
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
  # @param [Hash] options: plugin specific option. The keys must correspond
  #   to a plugin id, and the values will be passed only to the plugin identified by the key.
  #
  def alias(user_id:, previous_id:, options: {})
    # Run only if the object is enabled and was initialized
    return unless was_initialized? && enabled?

    # Log
    log = Itly::Loggers.vars_to_log user_id: user_id, previous_id: previous_id, options: options
    logger&.info "alias(#{log})"

    # Run on all plugins
    run_on_plugins do |plugin|
      plugin.alias user_id: user_id, previous_id: previous_id, options: options[plugin.id]
    end
    run_on_plugins do |plugin|
      plugin.post_alias user_id: user_id, previous_id: previous_id
    end
  end

  ##
  # Send +flush+ to your plugins.
  #
  # Call +flush+ on all plugins.
  #
  def flush
    # Run only if the object is enabled and was initialized
    return unless was_initialized? && enabled?

    # Log
    logger&.info 'flush()'

    # Run on all plugins
    run_on_plugins(&:flush)
  end

  ##
  # Send +shutdown+ to your plugins.
  #
  # Call +shutdown+ on all plugins.
  #
  def shutdown
    # Run only if the object is enabled and was initialized
    return unless was_initialized? && enabled?

    # Log
    logger&.info 'shutdown()'

    # Run on all plugins
    run_on_plugins(&:shutdown)
  end

  ##
  # Reset the SDK's (and all plugins') state. This method is usually called when a user logs out.
  #
  # Call +reset+ on all plugins.
  #
  def reset
    # Run only if the object is enabled and was initialized
    return unless was_initialized? && enabled?

    # Log
    logger&.info 'reset()'

    # Run on all plugins
    run_on_plugins(&:reset)
  end

  ##
  # Validate an Event
  #
  # Call +event+ on all plugins and collect their return values.
  #
  # @param [Event] event: the event to validate
  #
  # @return [Array] array of Itly::ValidationResponse objects that were generated by the plugins
  #
  def validate(event:)
    return unless was_initialized? && validation_enabled?

    # Log
    log = Itly::Loggers.vars_to_log event: event
    logger&.info "validate(#{log})"

    # Run on all plugins
    run_on_plugins { |plugin| plugin.validate event: event }
  end

  def is_loaded?
    !!@is_initialized
  end

  private

  def was_initialized?
    @is_initialized ? true : raise(InitializationError, 'Itly is not initialized. Call #load { |options| ... }')
  end

  def validate_and_send_to_plugins(action:, post_action:, event:, context: nil)
    # Perform validation on the context and the event
    context_validations, event_validations, is_valid = validate_context_and_event context, event
    validations = context_validations + event_validations

    # Call the action on all plugins
    event.properties.merge! context.properties if context

    if is_valid || @options.validation == Itly::Options::Validation::TRACK_INVALID
      run_on_plugins do |plugin|
        action.call(plugin, event) unless event.plugins[plugin.id].is_a?(FalseClass)
      end
    end

    # Log all errors
    log_validation_errors validations, event

    # Call the post_action on all plugins
    run_on_plugins do |plugin|
      post_action.call(plugin, event, validations) unless event.plugins[plugin.id].is_a?(FalseClass)
    end

    # Throw an exception if requested
    raise_validation_errors is_valid, validations, event
  end

  def validate_context_and_event(context, event)
    # Validate the context
    context_validations = (validate event: context if context) || []

    # Validate the event
    event_validations = validate(event: event) || []

    # Check if all validation succeeded
    is_valid = (context_validations + event_validations).all?(&:valid)

    [context_validations, event_validations, is_valid]
  end

  def log_validation_errors(validations, event)
    validations.reject(&:valid).each do |response|
      @options.logger&.error %(Validation error for "#{event.name}" )\
        "in #{response.plugin_id}. Message: #{response.message}"
    end
  end

  def raise_validation_errors(is_valid, validations, event)
    return if is_valid

    invalid_validations = validations.reject(&:valid)
    @options.on_validation_error&.call(event, invalid_validations)

    return unless @options.validation == Itly::Options::Validation::ERROR_ON_INVALID

    messages = invalid_validations.collect(&:message)
    messages = messages.select { |m| !m.nil? && m.length.positive? }
    messages << "Unknown error validating #{event.name}" if messages.empty?

    raise ValidationError, messages.join('. ')
  end
end
