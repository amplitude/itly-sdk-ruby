require 'itly-sdk'
require 'itly/plugin-schema_validator'
require 'itly/plugin-amplitude'
require 'itly/plugin-segment'

# Logger
logger = ::Logger.new $stdout, level: Logger::Severity::DEBUG

# Custom plugin
class CustomPlugin < Itly::Plugin
  def load(options:)
    @logger = options.logger
    logger.debug "#{plugin_id}: load()"
  end

  def identify(user_id:, properties:)
    logger.debug "#{plugin_id}: identify()"
  end

  def group(user_id:, group_id:, properties:)
    logger.debug "#{plugin_id}: group()"
  end

  def track(user_id:, event:)
    logger.debug "#{plugin_id}: track()"
  end

  def alias(user_id:, previous_id:)
    logger.debug "#{plugin_id}: alias()"
  end

  def flush
    logger.debug "#{plugin_id}: flush()"
  end

  def reset
    logger.debug "#{plugin_id}: reset()"
  end
end

# Instanciate plugins and Itly object
segment1 = Itly::Plugin::Segment.new write_key: 'account1_key'
segment2 = Itly::Plugin::Segment.new write_key: 'account2_key'
amplitude = Itly::Plugin::Amplitude.new api_key: 'ampl_key'
validator = Itly::Plugin::SchemaValidator.new schemas: {validation: 'schemas'}

itly = Itly.new

itly.load do |options|
  options.logger = logger
  options.plugins = [
    validator,
    segment1,
    segment2,
    amplitude
  ]
  option.context = {
    app_version: '1.2.3',
    platform: 'Linux'
  }
end

# Track events
itly.identify \
  user_id: 'user123',
  properties: {
    device: 'laptop'
  }

event = Itly::Event.new name: 'test_event'
itly.track \
  user_id: user_id,
  event: event

event = Itly::Event.new name: 'watch_video', properties: {video_id: '123'}
itly.track \
  user_id: user_id,
  event: event

