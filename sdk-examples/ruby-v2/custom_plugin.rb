# frozen_string_literal: true

##
# CustomPlugin
#
# rubocop:disable Lint/UnusedMethodArgument
class CustomPlugin < Itly::Plugin
  attr_accessor :logger

  def initialize(api_key:)
    super()
    @api_key = api_key
  end

  def load(options:)
    @logger = options.logger
    logger.debug "#{plugin_id}: load()"
  end

  def identify(user_id:, properties:)
    logger.debug "#{plugin_id}: identify(user_id: #{user_id}, properties: #{properties})"
  end

  def post_identify(user_id:, properties:, validation_results:)
    logger.debug "#{plugin_id}: post_identify(user_id: #{user_id}, properties: #{properties}, "\
      "validation_results: #{validation_results})"
  end

  def group(user_id:, group_id:, properties:)
    logger.debug "#{plugin_id}: group(user_id: #{user_id}, group_id: #{group_id}, properties: #{properties})"
  end

  def post_group(user_id:, group_id:, properties:, validation_results:)
    logger.debug "#{plugin_id}: post_group(user_id: #{user_id}, group_id: #{group_id}, "\
      "properties: #{properties}, validation_results: #{validation_results})"
  end

  def track(user_id:, event:)
    logger.debug "#{plugin_id}: track(event: #{event})"
  end

  def post_track(user_id:, event:, validation_results:)
    logger.debug "#{plugin_id}: post_track(event: #{event}, validation_results: #{validation_results})"
  end

  def alias(user_id:, previous_id:)
    logger.debug "#{plugin_id}: alias(user_id: #{user_id}, previous_id: #{previous_id})"
  end

  def post_alias(user_id:, previous_id:)
    logger.debug "#{plugin_id}: post_alias(user_id: #{user_id}, previous_id: #{previous_id})"
  end

  def flush
    logger.debug "#{plugin_id}: flush()"
  end

  def reset
    logger.debug "#{plugin_id}: reset()"
  end
end
# rubocop:enable Lint/UnusedMethodArgument
