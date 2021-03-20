# frozen_string_literal: true

require_relative 'itly'
require_relative 'itly_destination'
require_relative 'itly_options'
require_relative 'custom_plugin'
require_relative 'custom_events'

Itly.load(
  context: {
    requiredString: 'required context string',
    optionalEnum: 'Value 1'
  },
  destinations: ItlyDestination.new(
    iteratively: ItlyDestination::Iteratively.new(
      buffer_size: 10, max_retries: 25, retry_delay_min: 10.0, retry_delay_max: 3600.0
    )
  ),
  options: ItlyOptions.new(
    environment: Itly::Options::Environment::DEVELOPMENT,
    disabled: false,
    plugins: [CustomPlugin.new(api_key: 'abc123')],
    validation: Itly::Options::Validation::ERROR_ON_INVALID,
    logger: ::Logger.new($stdout, level: Logger::Severity::DEBUG)
  )
)

# Run Itly
user_id = 'a-user-id'

Itly.track(
  user_id: user_id,
  event: EventWithEnumTypes.new(
    required_num: EventWithEnumTypes::RequiredEnum::REQUIREDENUM1
  )
)

Itly.identify(
  user_id: 'tmpUserId',
  required_number: 42.0,
  optional_array: ['I\'m optional!']
)

Itly.alias(
  user_id: user_id,
  previous_id: 'tmpUserId'
)

Itly.group(
  user_id: user_id,
  group_id: 'groupId',
  required_boolean: true
)

Itly.track(
  user_id: user_id,
  event: EventNoProperties.new
)

Itly.track(
  user_id: user_id,
  event: EventWithConstTypes.new
)

Itly.track(
  user_id: user_id,
  event: EventWithOptionalProperties.new(
    optional_string: 'opt'
  )
)

Itly.event_with_optional_properties(
  user_id: user_id,
  optional_array_number: [2, 4],
  optional_number: 42.0,
  optional_string: 'hi'
)

Itly.event_with_optional_properties(
  user_id: user_id,
  optional_string: 'hi'
)

Itly.track(
  user_id: user_id,
  event: EventWithOptionalArrayTypes.new(
    optional_boolean_array: [true],
    optional_number_array: [2, 3, 1],
    optional_string_array: %w[this not required]
  )
)

Itly.track(
  user_id: user_id,
  event: EventWithAllProperties.new(
    required_array: %w[this is required],
    required_boolean: false,
    required_enum: EventWithAllProperties::RequiredEnum::ENUM1,
    required_integer: 42,
    required_number: 42.0,
    required_string: 'I\'m required 2',
    optional_string: 'I\'m optional'
  )
)

Itly.event_no_properties user_id: user_id

Itly.event_with_const_types user_id: user_id

Itly.event_max_int_for_test user_id: user_id, int_max10: 20

Itly.track(
  user_id: user_id,
  event: EventMaxIntForTest.new(int_max10: 20)
)

Itly.event_with_different_casing_types(
  user_id: user_id,
  enum_with_space: EventWithDifferentCasingTypes::EnumWithSpace::ENUMWITHSPACE,
  enum_snake_case: EventWithDifferentCasingTypes::EnumSnakeCase::ENUMSNAKECASE,
  enum_pascal_case: EventWithDifferentCasingTypes::EnumPascalCase::ENUMPASCALCASE,
  enum_camel_case: EventWithDifferentCasingTypes::EnumCamelCase::ENUMCAMELCASE,
  property_with_space: 'prop with space',
  property_with_snake_case: 'snake_case_prop_value',
  property_with_pascal_case: 'PascalCasePropValue',
  property_with_camel_case: 'camelCasePropValue'
)
