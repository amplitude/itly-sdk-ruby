# frozen_string_literal: true

describe 'integration' do
  include RspecIntegrationHelpers

  let(:logs) { StringIO.new }

  describe 'call methods that do not require validation' do
    [[true, 'with context'], [false, 'without context']].each do |with_context, description|
      describe description do
        let(:context) { { version: '1.2' } if with_context }

        it 'call #alias' do
          itly = Itly.new
          itly.load(context: context) do |options|
            itly_default_options options, logs
          end

          itly.alias(
            user_id: 'newID', previous_id: 'oldID',
            options: { 'acceptance_plugin' => AcceptancePluginCallOptions.new(specific: 'options for plugin') }
          )

          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['debug', '(spec) loaded'],
            ['info', 'alias(user_id: newID, previous_id: oldID, '\
                     'options: {"acceptance_plugin"=>#<AcceptancePluginCallOptions: options for plugin>})'],
            ['debug', '(spec) alias [newID, oldID, #<AcceptancePluginCallOptions: options for plugin>]'],
            ['debug', '(spec) post_alias [newID, oldID]']
          ]
        end

        it 'when the SDK is disabled' do
          itly = Itly.new
          itly.load(context: context) do |options|
            itly_default_options options, logs
            options.disabled = true
          end

          itly.alias user_id: 'newID', previous_id: 'oldID'

          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'Itly is disabled!']
          ]
        end
      end
    end
  end

  describe 'call methods with validation' do
    [[true, 'with context'], [false, 'without context']].each do |with_context, description|
      describe description do
        let(:context) { { version: '1.2' } if with_context }

        it 'call #identify' do
          itly = Itly.new
          itly.load(context: context) do |options|
            itly_default_options options, logs
          end

          itly.identify(
            user_id: 'newID', properties: { access_level: 'admin' },
            options: { 'acceptance_plugin' => AcceptancePluginCallOptions.new(specific: 'options for plugin') }
          )

          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['debug', '(spec) loaded'],
            ['info', 'identify(user_id: newID, properties: {:access_level=>"admin"}, '\
                     'options: {"acceptance_plugin"=>#<AcceptancePluginCallOptions: options for plugin>})'],
            ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:access_level=>"admin"}>)'],
            ['debug', '(spec) identify [newID, {:access_level=>"admin"}, '\
                      '#<AcceptancePluginCallOptions: options for plugin>]'],
            ['debug', '(spec) post_identify [newID, {:access_level=>"admin"}, '\
                      '[#<Itly::ValidationResponse: valid: true, plugin_id: id_validation_id, message: All good>]]']
          ]
        end

        describe 'with a validation error' do
          it 'when validation = ERROR_ON_INVALID' do
            itly = Itly.new
            itly.load(context: context) do |options|
              itly_default_options options, logs
              options.validation = Itly::Options::Validation::ERROR_ON_INVALID
            end

            expect do
              itly.identify user_id: 'newID', properties: { access_level: 'employee' }
            end.to raise_error(Itly::ValidationError, 'Not a valid access level')

            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['debug', '(spec) loaded'],
              ['info', 'identify(user_id: newID, properties: {:access_level=>"employee"})'],
              ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:access_level=>"employee"}>)'],
              ['error', 'Validation error for "identify" in id_validation_id. Message: Not a valid access level'],
              ['debug', '(spec) post_identify [newID, {:access_level=>"employee"}, '\
                        '[#<Itly::ValidationResponse: valid: false, plugin_id: id_validation_id, '\
                        'message: Not a valid access level>]]']
            ]
          end

          it 'when validation = TRACK_INVALID' do
            itly = Itly.new
            itly.load(context: context) do |options|
              itly_default_options options, logs
              options.validation = Itly::Options::Validation::TRACK_INVALID
            end

            expect do
              itly.identify user_id: 'newID', properties: { access_level: 'employee' }
            end.not_to raise_error

            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['debug', '(spec) loaded'],
              ['info', 'identify(user_id: newID, properties: {:access_level=>"employee"})'],
              ['info', 'validate(event: #<Itly::Event: name: identify, properties: {:access_level=>"employee"}>)'],
              ['debug', '(spec) identify [newID, {:access_level=>"employee"}, ]'],
              ['error', 'Validation error for "identify" in id_validation_id. Message: Not a valid access level'],
              ['debug', '(spec) post_identify [newID, {:access_level=>"employee"}, '\
                        '[#<Itly::ValidationResponse: valid: false, plugin_id: id_validation_id, '\
                        'message: Not a valid access level>]]']
            ]
          end

          it 'when validation = DISABLED' do
            itly = Itly.new
            itly.load(context: context) do |options|
              itly_default_options options, logs
              options.validation = Itly::Options::Validation::DISABLED
            end

            expect do
              itly.identify(
                user_id: 'newID', properties: { access_level: 'employee' },
                options: { 'acceptance_plugin' => AcceptancePluginCallOptions.new(specific: 'options for plugin') }
              )
            end.not_to raise_error

            expect_log_lines_to_equal [
              ['info', 'load()'],
              ['debug', '(spec) loaded'],
              ['info', 'identify(user_id: newID, properties: {:access_level=>"employee"}, '\
                       'options: {"acceptance_plugin"=>#<AcceptancePluginCallOptions: options for plugin>})'],
              ['debug', '(spec) identify [newID, {:access_level=>"employee"}, '\
                        '#<AcceptancePluginCallOptions: options for plugin>]'],
              ['debug', '(spec) post_identify [newID, {:access_level=>"employee"}, []]']
            ]
          end
        end

        it 'when the SDK is disabled' do
          itly = Itly.new
          itly.load(context: context) do |options|
            itly_default_options options, logs
            options.disabled = true
          end

          itly.identify user_id: 'newID', properties: { access_level: 'admin' }

          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'Itly is disabled!']
          ]
        end
      end
    end
  end

  describe 'call methods with context' do
    [[true, 'with context'], [false, 'without context']].each do |with_context, description|
      describe description do
        let(:context) { { version: '1.2' } if with_context }

        it 'call #track' do
          itly = Itly.new
          itly.load(context: context) do |options|
            itly_default_options options, logs
          end

          itly.track \
            user_id: 'userID',
            event: Itly::Event.new(
              name: 'user_signed_in',
              properties: { email: 'user@mail.com' }
            )

          expected = [
            ['info', 'load()'],
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
              ['debug', '(spec) track [userID, #<Itly::Event: name: user_signed_in, '\
                        'properties: {:email=>"user@mail.com", :version=>"1.2"}>, ]'],
              ['debug', '(spec) post_track [userID, #<Itly::Event: name: user_signed_in, '\
                        'properties: {:email=>"user@mail.com", :version=>"1.2"}>, '\
                        '[#<Itly::ValidationResponse: valid: true, plugin_id: sign_validation_id, message: >]]']
            ]
          else
            expected += [
              ['debug', '(spec) track [userID, #<Itly::Event: name: user_signed_in, '\
                        'properties: {:email=>"user@mail.com"}>, ]'],
              ['debug', '(spec) post_track [userID, #<Itly::Event: name: user_signed_in, '\
                        'properties: {:email=>"user@mail.com"}>, '\
                        '[#<Itly::ValidationResponse: valid: true, plugin_id: sign_validation_id, message: >]]']
            ]
          end

          expect_log_lines_to_equal expected
        end

        describe 'with a validation error' do
          it 'when validation = ERROR_ON_INVALID' do
            itly = Itly.new
            itly.load(context: context) do |options|
              itly_default_options options, logs
              options.validation = Itly::Options::Validation::ERROR_ON_INVALID
            end

            expect do
              itly.track \
                user_id: 'userID',
                event: Itly::Event.new(
                  name: 'user_signed_in',
                  properties: { wrong_key: 'user@mail.com' }
                )
            end.to raise_error(Itly::ValidationError, 'Missing email')

            expected = [
              ['info', 'load()'],
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
                ['debug', '(spec) post_track [userID, #<Itly::Event: name: user_signed_in, '\
                          'properties: {:wrong_key=>"user@mail.com", :version=>"1.2"}>, '\
                          '[#<Itly::ValidationResponse: valid: false, plugin_id: sign_validation_id, '\
                          'message: Missing email>]]']
              ]
            else
              expected += [
                ['debug', '(spec) post_track [userID, #<Itly::Event: name: user_signed_in, '\
                          'properties: {:wrong_key=>"user@mail.com"}>, [#<Itly::ValidationResponse: valid: false, '\
                          'plugin_id: sign_validation_id, message: Missing email>]]']
              ]
            end

            expect_log_lines_to_equal expected
          end

          it 'when validation = TRACK_INVALID' do
            itly = Itly.new
            itly.load(context: context) do |options|
              itly_default_options options, logs
              options.validation = Itly::Options::Validation::TRACK_INVALID
            end

            expect do
              itly.track \
                user_id: 'userID',
                event: Itly::Event.new(
                  name: 'user_signed_in',
                  properties: { wrong_key: 'user@mail.com' }
                )
            end.not_to raise_error

            expected = [
              ['info', 'load()'],
              ['debug', '(spec) loaded'],
              ['info', 'track(user_id: userID, event: user_signed_in, properties: {:wrong_key=>"user@mail.com"})']
            ]

            if with_context
              expected << ['info', 'validate(event: #<Itly::Event: name: context, properties: {:version=>"1.2"}>)']
            end

            expected << ['info', 'validate(event: #<Itly::Event: name: user_signed_in, '\
                                 'properties: {:wrong_key=>"user@mail.com"}>)']

            expected << if with_context
                          ['debug', '(spec) track [userID, #<Itly::Event: name: user_signed_in, '\
                                                'properties: {:wrong_key=>"user@mail.com", :version=>"1.2"}>, ]']
                        else
                          ['debug', '(spec) track [userID, #<Itly::Event: name: user_signed_in, '\
                                                'properties: {:wrong_key=>"user@mail.com"}>, ]']
                        end

            expected << ['error', 'Validation error for "user_signed_in" in sign_validation_id. Message: Missing email']

            expected += if with_context
                          [
                            ['debug', '(spec) post_track [userID, #<Itly::Event: name: user_signed_in, '\
                                      'properties: {:wrong_key=>"user@mail.com", :version=>"1.2"}>, '\
                                      '[#<Itly::ValidationResponse: valid: false, plugin_id: sign_validation_id, '\
                                      'message: Missing email>]]']
                          ]
                        else
                          [
                            ['debug', '(spec) post_track [userID, #<Itly::Event: name: user_signed_in, '\
                                      'properties: {:wrong_key=>"user@mail.com"}>, '\
                                      '[#<Itly::ValidationResponse: valid: false, plugin_id: sign_validation_id, '\
                                      'message: Missing email>]]']
                          ]
                        end

            expect_log_lines_to_equal expected
          end

          it 'when validation = DISABLED' do
            itly = Itly.new
            itly.load(context: context) do |options|
              itly_default_options options, logs
              options.validation = Itly::Options::Validation::DISABLED
            end

            expect do
              itly.track \
                user_id: 'userID',
                event: Itly::Event.new(
                  name: 'user_signed_in',
                  properties: { wrong_key: 'user@mail.com' }
                )
            end.not_to raise_error

            expected = [
              ['info', 'load()'],
              ['debug', '(spec) loaded'],
              ['info', 'track(user_id: userID, event: user_signed_in, properties: {:wrong_key=>"user@mail.com"})']
            ]

            expected += if with_context
                          [
                            ['debug', '(spec) track [userID, #<Itly::Event: name: user_signed_in, '\
                                      'properties: {:wrong_key=>"user@mail.com", :version=>"1.2"}>, ]'],
                            ['debug', '(spec) post_track [userID, #<Itly::Event: name: user_signed_in, '\
                                      'properties: {:wrong_key=>"user@mail.com", :version=>"1.2"}>, []]']
                          ]
                        else
                          [
                            ['debug', '(spec) track [userID, #<Itly::Event: name: user_signed_in, '\
                                      'properties: {:wrong_key=>"user@mail.com"}>, ]'],
                            ['debug', '(spec) post_track [userID, #<Itly::Event: name: user_signed_in, '\
                                      'properties: {:wrong_key=>"user@mail.com"}>, []]']
                          ]
                        end

            expect_log_lines_to_equal expected
          end
        end

        it 'when the SDK is disabled' do
          itly = Itly.new
          itly.load(context: context) do |options|
            itly_default_options options, logs
            options.disabled = true
          end

          itly.track \
            user_id: 'userID',
            event: Itly::Event.new(
              name: 'user_signed_in',
              properties: { email: 'user@mail.com' }
            )

          expect_log_lines_to_equal [
            ['info', 'load()'],
            ['info', 'Itly is disabled!']
          ]
        end
      end
    end
  end
end
