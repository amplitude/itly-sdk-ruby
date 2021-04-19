# frozen_string_literal: true

class AcceptancePlugin < Itly::Plugin
  def load(options:)
    super
    # Keep a reference to the logger, for test purpose
    @logger = options.logger

    @logger.debug '(spec) loaded'
  end

  def alias(user_id:, previous_id:, options:)
    super
    @logger.debug "(spec) alias [#{user_id}, #{previous_id}, #{options}]"
  end

  def post_alias(user_id:, previous_id:)
    super
    @logger.debug "(spec) post_alias [#{user_id}, #{previous_id}]"
  end

  def identify(user_id:, properties:, options:)
    super
    @logger.debug "(spec) identify [#{user_id}, #{properties}, #{options}]"
  end

  def post_identify(user_id:, properties:, validation_results:)
    super
    @logger.debug "(spec) post_identify [#{user_id}, #{properties}, [#{validation_results.collect(&:to_s).join ', '}]]"
  end

  def track(user_id:, event:, options:)
    super
    @logger.debug "(spec) track [#{user_id}, #{event}, #{options}]"
  end

  def post_track(user_id:, event:, validation_results:)
    super
    @logger.debug "(spec) post_track [#{user_id}, #{event}, [#{validation_results.collect(&:to_s).join ', '}]]"
  end

  def validate(event:)
    super
    case event.name
    when 'identify'
      if %w[admin user].include? event.properties[:access_level]
        Itly::ValidationResponse.new valid: true, plugin_id: 'id_validation_id', message: 'All good'
      else
        Itly::ValidationResponse.new \
          valid: false, plugin_id: 'id_validation_id',
          message: 'Not a valid access level'
      end
    when 'user_signed_in'
      if event.properties.key? :email
        Itly::ValidationResponse.new valid: true, plugin_id: 'sign_validation_id'
      else
        Itly::ValidationResponse.new valid: false, plugin_id: 'sign_validation_id', message: 'Missing email'
      end
    end
  end
end
