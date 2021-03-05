# frozen_string_literal: true

# rubocop:disable Layout/LineLength
describe 'integration' do
  include RspecIntegrationHelpers

  let(:logs) { StringIO.new }

  before do
    klass = Class.new(Itly::Plugin) do
      def load(options:)
        # Keep a reference to the logger, for test purpose
        @logger = options.logger

        # Set requirements in the plugin-specific options
        plugin_options = get_plugin_options options

        if !plugin_options.key?(:required_version) || !plugin_options[:required_version].is_a?(Integer)
          raise 'The required_version option key is not found or is not an Integer'
        end
        raise 'The minimum compatible version is 4' if plugin_options[:required_version] < 4

        # Log the success
        @logger.debug '(spec) loaded'
      end

      def alias(user_id:, previous_id:)
        @logger.debug "(spec) alias [#{user_id}, #{previous_id}]"
      end

      def post_alias(user_id:, previous_id:)
        @logger.debug "(spec) post_alias [#{user_id}, #{previous_id}]"
      end

      def identify(user_id:, properties:)
        @logger.debug "(spec) identify [#{user_id}, #{properties}]"
      end

      def post_identify(user_id:, properties:, validation_results:)
        @logger.debug "(spec) post_identify [#{user_id}, #{properties}, [#{validation_results.collect(&:to_s).join ', '}]]"
      end

      def track(user_id:, event:)
        @logger.debug "(spec) track [#{user_id}, #{event}]"
      end

      def post_track(user_id:, event:, validation_results:)
        @logger.debug "(spec) post_track [#{user_id}, #{event}, [#{validation_results.collect(&:to_s).join ', '}]]"
      end

      def validate(event:)
        case event.name
        when 'identify'
          if %w[admin user].include? event.properties[:access_level]
            Itly::ValidationResponse.new valid: true, plugin_id: 'id_validation_id', message: 'All good'
          else
            Itly::ValidationResponse.new valid: false, plugin_id: 'id_validation_id',
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
    Object.const_set 'AcceptancePlugin', klass
  end

  after do
    Object.send :remove_const, 'AcceptancePlugin'
  end

  describe 'receive plugin-specific options on #load' do
    [[true, 'with context'], [false, 'without context']].each do |with_context, description|
      describe description do
        describe 'plugin require a specific option' do
          let(:itly) { Itly.new }

          it 'in production' do
            itly.load do |options|
              itly_default_options options, logs
              options.plugins.acceptance_plugin = {}
              options.environment = Itly::Options::Environment::PRODUCTION
              options.context = { version: '1.2' } if with_context
            end

            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['error', 'Itly Error in AcceptancePlugin. RuntimeError: The required_version option key '\
                        'is not found or is not an Integer']
            ]
          end

          it 'in development' do
            expect do
              itly.load do |options|
                itly_default_options options, logs
                options.plugins.acceptance_plugin = {}
                options.environment = Itly::Options::Environment::DEVELOPMENT
                options.context = { version: '1.2' } if with_context
              end
            end.to raise_error(RuntimeError, 'The required_version option key is not found or is not an Integer')
          end
        end

        describe 'plugin can check for options values' do
          let(:itly) { Itly.new }

          it 'in production' do
            itly.load do |options|
              itly_default_options options, logs
              options.plugins.acceptance_plugin = { required_version: 2 }
              options.environment = Itly::Options::Environment::PRODUCTION
              options.context = { version: '1.2' } if with_context
            end

            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['error', 'Itly Error in AcceptancePlugin. RuntimeError: The minimum compatible version is 4']
            ]
          end

          it 'in development' do
            expect do
              itly.load do |options|
                itly_default_options options, logs
                options.plugins.acceptance_plugin = { required_version: 2 }
                options.environment = Itly::Options::Environment::DEVELOPMENT
                options.context = { version: '1.2' } if with_context
              end
            end.to raise_error(RuntimeError, 'The minimum compatible version is 4')
          end
        end

        it 'succeed when all requirements are met' do
          itly = Itly.new
          itly.load do |options|
            itly_default_options options, logs
            options.plugins.acceptance_plugin = { required_version: 4 }
            options.context = { version: '1.2' } if with_context
          end

          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['warn', 'Environment not specified. Automatically set to development'],
            ['debug', '(spec) loaded']
          ]
        end
      end
    end
  end

  describe 'call methods that do not require validation' do
    [[true, 'with context'], [false, 'without context']].each do |with_context, description|
      describe description do
        it 'call #alias' do
          itly = Itly.new
          itly.load do |options|
            itly_default_options options, logs
            options.context = { version: '1.2' } if with_context
          end

          itly.alias user_id: 'newID', previous_id: 'oldID'

          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['warn', 'Environment not specified. Automatically set to development'],
            ['debug', '(spec) loaded'],
            ['info', 'alias(user_id: newID, previous_id: oldID)'],
            ['debug', '(spec) alias [newID, oldID]'],
            ['debug', '(spec) post_alias [newID, oldID]']
          ]
        end

        it 'when the SDK is disabled' do
          itly = Itly.new
          itly.load do |options|
            itly_default_options options, logs
            options.disabled = true
            options.context = { version: '1.2' } if with_context
          end

          itly.alias user_id: 'newID', previous_id: 'oldID'

          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'Itly is disabled!'],
            ['warn', 'Environment not specified. Automatically set to development'],
            ['debug', '(spec) loaded']
          ]
        end
      end
    end
  end

  describe 'call methods with validation' do
    [[true, 'with context'], [false, 'without context']].each do |with_context, description|
      describe description do
        it 'call #identify' do
          itly = Itly.new
          itly.load do |options|
            itly_default_options options, logs
            options.context = { version: '1.2' } if with_context
          end

          itly.identify user_id: 'newID', properties: { access_level: 'admin' }

          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['warn', 'Environment not specified. Automatically set to development'],
            ['debug', '(spec) loaded'],
            ['info', 'identify(user_id: newID, properties: {:access_level=>"admin"})'],
            ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:access_level=>"admin"}>)'],
            ['debug', '(spec) identify [newID, #<Itly::Event: name: identify, properties: {:access_level=>"admin"}>]'],
            ['debug', '(spec) post_identify [newID, #<Itly::Event: name: identify, properties: {:access_level=>"admin"}>, '\
                      '[#<Itly::ValidationResponse: valid: true, plugin_id: id_validation_id, message: All good>]]']
          ]
        end

        describe 'with a validation error' do
          it 'when validation = ERROR_ON_INVALID' do
            itly = Itly.new
            itly.load do |options|
              itly_default_options options, logs
              options.validation = Itly::Options::Validation::ERROR_ON_INVALID
              options.context = { version: '1.2' } if with_context
            end

            expect do
              itly.identify user_id: 'newID', properties: { access_level: 'employee' }
            end.to raise_error(Itly::ValidationError, 'Not a valid access level')

            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['warn', 'Environment not specified. Automatically set to development'],
              ['debug', '(spec) loaded'],
              ['info', 'identify(user_id: newID, properties: {:access_level=>"employee"})'],
              ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:access_level=>"employee"}>)'],
              ['error', 'Validation error for "identify" in id_validation_id. Message: Not a valid access level'],
              ['debug', '(spec) post_identify [newID, #<Itly::Event: name: identify, properties: {:access_level=>"employee"}>, '\
                        '[#<Itly::ValidationResponse: valid: false, plugin_id: id_validation_id, message: Not a valid access level>]]']
            ]
          end

          it 'when validation = TRACK_INVALID' do
            itly = Itly.new
            itly.load do |options|
              itly_default_options options, logs
              options.validation = Itly::Options::Validation::TRACK_INVALID
              options.context = { version: '1.2' } if with_context
            end

            expect do
              itly.identify user_id: 'newID', properties: { access_level: 'employee' }
            end.not_to raise_error

            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['warn', 'Environment not specified. Automatically set to development'],
              ['debug', '(spec) loaded'],
              ['info', 'identify(user_id: newID, properties: {:access_level=>"employee"})'],
              ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:access_level=>"employee"}>)'],
              ['debug',
               '(spec) identify [newID, #<Itly::Event: name: identify, properties: {:access_level=>"employee"}>]'],
              ['error', 'Validation error for "identify" in id_validation_id. Message: Not a valid access level'],
              ['debug', '(spec) post_identify [newID, #<Itly::Event: name: identify, properties: {:access_level=>"employee"}>, '\
                        '[#<Itly::ValidationResponse: valid: false, plugin_id: id_validation_id, message: Not a valid access level>]]']
            ]
          end

          it 'when validation = DISABLED' do
            itly = Itly.new
            itly.load do |options|
              itly_default_options options, logs
              options.validation = Itly::Options::Validation::DISABLED
              options.context = { version: '1.2' } if with_context
            end

            expect do
              itly.identify user_id: 'newID', properties: { access_level: 'employee' }
            end.not_to raise_error

            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['warn', 'Environment not specified. Automatically set to development'],
              ['debug', '(spec) loaded'],
              ['info', 'identify(user_id: newID, properties: {:access_level=>"employee"})'],
              ['debug',
               '(spec) identify [newID, #<Itly::Event: name: identify, properties: {:access_level=>"employee"}>]'],
              ['debug',
               '(spec) post_identify [newID, #<Itly::Event: name: identify, properties: {:access_level=>"employee"}>, []]']
            ]
          end
        end

        it 'when the SDK is disabled' do
          itly = Itly.new
          itly.load do |options|
            itly_default_options options, logs
            options.disabled = true
            options.context = { version: '1.2' } if with_context
          end

          itly.identify user_id: 'newID', properties: { access_level: 'admin' }

          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'Itly is disabled!'],
            ['warn', 'Environment not specified. Automatically set to development'],
            ['debug', '(spec) loaded']
          ]
        end
      end
    end
  end

  describe 'call methods with context' do
    [[true, 'with context'], [false, 'without context']].each do |with_context, description|
      describe description do
        it 'call #track' do
          itly = Itly.new
          itly.load do |options|
            itly_default_options options, logs
            options.context = { version: '1.2' } if with_context
          end

          itly.track user_id: 'userID',
            event: Itly::Event.new(name: 'user_signed_in', properties: { email: 'user@mail.com' })

          expected = [
            ['info', 'load()'],
            ['warn', 'Environment not specified. Automatically set to development'],
            ['debug', '(spec) loaded'],
            ['info', 'track(user_id: userID, event: user_signed_in, properties: {:email=>"user@mail.com"})']
          ]

          if with_context
            expected << ['info', 'validate(event: #<Itly::Event: name: context, properties: {:version=>"1.2"}>)']
          end

          expected << ['info',
                       'validate(event: #<Itly::Event: name: user_signed_in, properties: {:email=>"user@mail.com"}>)']

          if with_context
            expected += [
              ['debug',
               '(spec) track [userID, #<Itly::Event: name: user_signed_in, properties: {:email=>"user@mail.com", :version=>"1.2"}>]'],
              ['debug', '(spec) post_track [userID, #<Itly::Event: name: user_signed_in, properties: {:email=>"user@mail.com", :version=>"1.2"}>, '\
                '[#<Itly::ValidationResponse: valid: true, plugin_id: sign_validation_id, message: >]]']
            ]
          else
            expected += [
              ['debug',
               '(spec) track [userID, #<Itly::Event: name: user_signed_in, properties: {:email=>"user@mail.com"}>]'],
              ['debug', '(spec) post_track [userID, #<Itly::Event: name: user_signed_in, properties: {:email=>"user@mail.com"}>, '\
                '[#<Itly::ValidationResponse: valid: true, plugin_id: sign_validation_id, message: >]]']
            ]
          end

          expect_log_lines_to_equal expected
        end

        describe 'with a validation error' do
          it 'when validation = ERROR_ON_INVALID' do
            itly = Itly.new
            itly.load do |options|
              itly_default_options options, logs
              options.validation = Itly::Options::Validation::ERROR_ON_INVALID
              options.context = { version: '1.2' } if with_context
            end

            expect do
              itly.track user_id: 'userID',
                event: Itly::Event.new(name: 'user_signed_in', properties: { wrong_key: 'user@mail.com' })
            end.to raise_error(Itly::ValidationError, 'Missing email')

            expected = [
              ['info', 'load()'],
              ['warn', 'Environment not specified. Automatically set to development'],
              ['debug', '(spec) loaded'],
              ['info', 'track(user_id: userID, event: user_signed_in, properties: {:wrong_key=>"user@mail.com"})']
            ]

            if with_context
              expected << ['info', 'validate(event: #<Itly::Event: name: context, properties: {:version=>"1.2"}>)']
            end

            expected += [
              ['info',
               'validate(event: #<Itly::Event: name: user_signed_in, properties: {:wrong_key=>"user@mail.com"}>)'],
              ['error', 'Validation error for "user_signed_in" in sign_validation_id. Message: Missing email']
            ]

            if with_context
              expected += [
                ['debug', '(spec) post_track [userID, #<Itly::Event: name: user_signed_in, properties: {:wrong_key=>"user@mail.com", :version=>"1.2"}>, '\
                  '[#<Itly::ValidationResponse: valid: false, plugin_id: sign_validation_id, message: Missing email>]]']
              ]
            else
              expected += [
                ['debug', '(spec) post_track [userID, #<Itly::Event: name: user_signed_in, properties: {:wrong_key=>"user@mail.com"}>, '\
                  '[#<Itly::ValidationResponse: valid: false, plugin_id: sign_validation_id, message: Missing email>]]']
              ]
            end

            expect_log_lines_to_equal expected
          end

          it 'when validation = TRACK_INVALID' do
            itly = Itly.new
            itly.load do |options|
              itly_default_options options, logs
              options.validation = Itly::Options::Validation::TRACK_INVALID
              options.context = { version: '1.2' } if with_context
            end

            expect do
              itly.track user_id: 'userID',
                event: Itly::Event.new(name: 'user_signed_in', properties: { wrong_key: 'user@mail.com' })
            end.not_to raise_error

            expected = [
              ['info', 'load()'],
              ['warn', 'Environment not specified. Automatically set to development'],
              ['debug', '(spec) loaded'],
              ['info', 'track(user_id: userID, event: user_signed_in, properties: {:wrong_key=>"user@mail.com"})']
            ]

            if with_context
              expected << ['info', 'validate(event: #<Itly::Event: name: context, properties: {:version=>"1.2"}>)']
            end

            expected << ['info',
                         'validate(event: #<Itly::Event: name: user_signed_in, properties: {:wrong_key=>"user@mail.com"}>)']

            if with_context
              expected << ['debug',
                           '(spec) track [userID, #<Itly::Event: name: user_signed_in, properties: {:wrong_key=>"user@mail.com", :version=>"1.2"}>]']
            else
              expected << ['debug',
                           '(spec) track [userID, #<Itly::Event: name: user_signed_in, properties: {:wrong_key=>"user@mail.com"}>]']
            end

            expected << ['error', 'Validation error for "user_signed_in" in sign_validation_id. Message: Missing email']

            if with_context
              expected += [
                ['debug', '(spec) post_track [userID, #<Itly::Event: name: user_signed_in, properties: {:wrong_key=>"user@mail.com", :version=>"1.2"}>, '\
                  '[#<Itly::ValidationResponse: valid: false, plugin_id: sign_validation_id, message: Missing email>]]']
              ]
            else
              expected += [
                ['debug', '(spec) post_track [userID, #<Itly::Event: name: user_signed_in, properties: {:wrong_key=>"user@mail.com"}>, '\
                  '[#<Itly::ValidationResponse: valid: false, plugin_id: sign_validation_id, message: Missing email>]]']
              ]
            end

            expect_log_lines_to_equal expected
          end

          it 'when validation = DISABLED' do
            itly = Itly.new
            itly.load do |options|
              itly_default_options options, logs
              options.validation = Itly::Options::Validation::DISABLED
              options.context = { version: '1.2' } if with_context
            end

            expect do
              itly.track user_id: 'userID',
                event: Itly::Event.new(name: 'user_signed_in', properties: { wrong_key: 'user@mail.com' })
            end.not_to raise_error

            expected = [
              ['info', 'load()'],
              ['warn', 'Environment not specified. Automatically set to development'],
              ['debug', '(spec) loaded'],
              ['info', 'track(user_id: userID, event: user_signed_in, properties: {:wrong_key=>"user@mail.com"})']
            ]

            if with_context
              expected += [
                ['debug',
                 '(spec) track [userID, #<Itly::Event: name: user_signed_in, properties: {:wrong_key=>"user@mail.com", :version=>"1.2"}>]'],
                ['debug',
                 '(spec) post_track [userID, #<Itly::Event: name: user_signed_in, properties: {:wrong_key=>"user@mail.com", :version=>"1.2"}>, []]']
              ]
            else
              expected += [
                ['debug',
                 '(spec) track [userID, #<Itly::Event: name: user_signed_in, properties: {:wrong_key=>"user@mail.com"}>]'],
                ['debug',
                 '(spec) post_track [userID, #<Itly::Event: name: user_signed_in, properties: {:wrong_key=>"user@mail.com"}>, []]']
              ]
            end

            expect_log_lines_to_equal expected
          end
        end

        it 'when the SDK is disabled' do
          itly = Itly.new
          itly.load do |options|
            itly_default_options options, logs
            options.disabled = true
            options.context = { version: '1.2' } if with_context
          end

          itly.track user_id: 'userID',
            event: Itly::Event.new(name: 'user_signed_in', properties: { email: 'user@mail.com' })

          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'Itly is disabled!'],
            ['warn', 'Environment not specified. Automatically set to development'],
            ['debug', '(spec) loaded']
          ]
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
