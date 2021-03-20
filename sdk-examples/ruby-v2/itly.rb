# frozen_string_literal: true

require 'itly/plugin-schema_validator'
require 'itly/plugin-iteratively'
require 'itly/plugin-amplitude'
require 'itly/plugin-mixpanel'

# Alias Itly class
ItlyBase = Itly
Object.send :remove_const, 'Itly'

##
# Itly wrapper
#
class Itly
  ##
  # Inject ItlyBase nested classes
  class Plugin < ItlyBase::Plugin; end

  class Event < ItlyBase::Event; end

  class Options < ItlyBase::Options; end

  class ValidationResponse < ItlyBase::ValidationResponse; end

  class InitializationError < ItlyBase::InitializationError; end

  class ValidationError < ItlyBase::ValidationError; end

  class RemoteError < ItlyBase::RemoteError; end

  ##
  # The base Itly object
  @itly = ItlyBase.new

  ##
  # Load method
  def self.load(context:, destinations:, options:)
    production = options.environment == Itly::Options::Environment::DEVELOPMENT

    iteratively_options = destinations.iteratively.merge(
      {
        api_key: (production ? 'czplcshExmKFsSZewp7ZNT5FwmEq3Icm' : 'kYOq_MeI9FIv0KUmWOEaNY8UQozsyWbP'),
        url: 'http://localhost:4000/t/version/5cc4ed48-fe02-4fc1-aa52-97fa1f0f8ff3'
      }
    )

    @itly.load do |o|
      o.plugins = [
        Itly::Plugin::SchemaValidator.new(schemas: validation_schemas),
        Itly::Plugin::Iteratively.new(**iteratively_options),
        Itly::Plugin::Amplitude.new(
          api_key: (production ? 'bb274b5fee57618077aa34fac567b8db' : 'abc123')
        ),
        Itly::Plugin::Mixpanel.new(
          project_token: (production ? 'czplcshExmKFsSZewp7ZNT5FwmEq3Icm' : 'kYOq_MeI9FIv0KUmWOEaNY8UQozsyWbP')
        ),
        Itly::Plugin::Mixpanel.new(
          project_token: (production ? '67a8ece0a81e35124d7c23c06b04c52f' : 'CvU1TXIk6zSKuN7Vyx3FMT7cqzyvY5th')
        )
      ] + options.plugins
      o.context = context
      o.disabled = options.disabled
      o.environment = options.environment
      o.validation = options.validation
      o.logger = options.logger
    end
  end

  ####
  # High level methods for custom made utilities
  #
  ####

  ##
  # Set or update a user's properties.
  #
  # @param [String] user_id: The user's ID.
  # @param [Integer] required_number: Description for identify requiredNumber
  # @param [Array] optional_array: Description for identify optionalArray
  #
  def self.identify(user_id:, required_number:, optional_array: [])
    @itly.identify user_id: user_id, properties: {
      requiredNumber: required_number,
      optionalArray: optional_array
    }.compact
  end

  ##
  # Set or update a user group's properties.
  #
  # @param [String] user_id: The user's ID.
  # @param [String] group_id: The group's ID.
  # @param [TrueClass/FalseClass] required_boolean: Description for group requiredBoolean
  # @param [String] optional_string: Description for group optionalString
  #
  def self.group(user_id:, group_id:, required_boolean:, optional_string: nil)
    @itly.group user_id: user_id, group_id: group_id, properties: {
      requiredBoolean: required_boolean,
      optionalString: optional_string
    }.compact
  end

  ##
  # Track event 'Event No Properties'
  #
  # Event w no properties description
  #
  # @param [String] user_id: The user's ID.
  #
  def self.event_no_properties(user_id:)
    @itly.track(
      user_id: user_id,
      event: EventNoProperties.new
    )
  end

  ##
  # Track event 'Event With Array Types'
  #
  # Description for event with Array Types
  #
  # @param [String] user_id: The user's ID.
  #
  def self.event_with_const_types(user_id:)
    @itly.track(
      user_id: user_id,
      event: EventWithConstTypes.new
    )
  end

  ##
  # Track event 'Event With Optional Properties'
  #
  # Event w optional properties description
  #
  # @param [String] user_id: The user's ID.
  # @param [Array] optional_array_number: Property has no description provided in tracking plan.
  # @param [Array] optional_array_string: Property has no description provided in tracking plan.
  # @param [TrueClass/FalseClass] optional_boolean: Property has no description provided in tracking plan.
  # @param [Integer] optional_number: Property has no description provided in tracking plan.
  # @param [String] optional_string: Optional String property description
  #
  def self.event_with_optional_properties(
    user_id:, optional_array_number: nil, optional_array_string: nil,
    optional_boolean: nil, optional_number: nil, optional_string: nil
  )
    @itly.track(
      user_id: user_id,
      event: EventWithOptionalProperties.new(
        optional_array_number: optional_array_number,
        optional_array_string: optional_array_string,
        optional_boolean: optional_boolean,
        optional_number: optional_number,
        optional_string: optional_string
      )
    )
  end

  ##
  # Track event 'EventMaxIntForTest'
  #
  # Event to test schema validation
  #
  # @params [Integer] intMax10: property to test schema validation
  #
  def self.event_max_int_for_test(user_id:, int_max10:)
    @itly.track(
      user_id: user_id,
      event: EventMaxIntForTest.new(int_max10: int_max10)
    )
  end

  ##
  # Track event 'event withDifferent_CasingTypes'
  #
  # Description for case with space
  #
  # @param [String] enum_camel_case: descriptionForEnumCamelCase
  # @param [String] enum_pascal_case: DescirptionForEnumPascalCase
  # @param [String] enum_snake_case: description_for_enum_snake_case
  # @param [String] enum_with_space: Description for enum with space
  # @param [String] property_with_camel_case: descriptionForCamelCase
  # @param [String] property_with_pascal_case: DescriptionForPascalCase
  # @param [String] property_with_snake_case: Description_for_snake_case
  # @param [String] property_with_space: Description for case with space
  #
  def self.event_with_different_casing_types(
    user_id:,
    property_with_camel_case:, property_with_pascal_case:, property_with_snake_case:, property_with_space:,
    enum_camel_case: EventWithDifferentCasingTypes::EnumCamelCase::ENUMCAMELCASE,
    enum_pascal_case: EventWithDifferentCasingTypes::EnumPascalCase::ENUMPASCALCASE,
    enum_snake_case: EventWithDifferentCasingTypes::EnumSnakeCase::ENUMSNAKECASE,
    enum_with_space: EventWithDifferentCasingTypes::EnumWithSpace::ENUMWITHSPACE
  )
    @itly.track(
      user_id: user_id,
      event: EventWithDifferentCasingTypes.new(
        enum_camel_case: enum_camel_case,
        enum_pascal_case: enum_pascal_case,
        enum_snake_case: enum_snake_case,
        enum_with_space: enum_with_space,
        property_with_camel_case: property_with_camel_case,
        property_with_pascal_case: property_with_pascal_case,
        property_with_snake_case: property_with_snake_case,
        property_with_space: property_with_space
      )
    )
  end

  ####
  # Low-level methods to directly access the itly object
  #
  ####

  ##
  # Track an event.
  #
  # @param [Itly::Event] event: The event to track
  #
  def self.track(user_id:, event:)
    @itly.track user_id: user_id, event: event
  end

  ##
  # Alias one user ID to another.
  #
  # @param [String] user_id: The user's new ID.
  # @param [String] previous_id: The user's previous ID.
  #
  def self.alias(user_id:, previous_id:)
    @itly.alias user_id: user_id, previous_id: previous_id
  end

  # rubocop:disable Layout/LineLength
  def self.validation_schemas
    {
      context: '{"$id":"https://iterative.ly/company/77b37977-cb3a-42eb-bce3-09f5f7c3adb7/context","$schema":"http://json-schema.org/draft-07/schema#","title":"Context","description":"","type":"object","properties":{"requiredString":{"description":"description for context requiredString","type":"string"},"optionalEnum":{"description":"description for context optionalEnum","enum":["Value 1","Value 2"]}},"additionalProperties":false,"required":["requiredString"]}',
      group: '{"$id":"https://iterative.ly/company/77b37977-cb3a-42eb-bce3-09f5f7c3adb7/group","$schema":"http://json-schema.org/draft-07/schema#","title":"Group","description":"","type":"object","properties":{"requiredBoolean":{"description":"Description for group requiredBoolean","type":"boolean"},"optionalString":{"description":"Description for group optionalString","type":"string"}},"additionalProperties":false,"required":["requiredBoolean"]}',
      identify: '{"$id":"https://iterative.ly/company/77b37977-cb3a-42eb-bce3-09f5f7c3adb7/identify","$schema":"http://json-schema.org/draft-07/schema#","title":"Identify","description":"","type":"object","properties":{"optionalArray":{"description":"Description for identify optionalArray","type":"array","uniqueItems":false,"items":{"type":"string"}},"requiredNumber":{"description":"Description for identify requiredNumber","type":"number"}},"additionalProperties":false,"required":["requiredNumber"]}',
      'Event No Properties': '{"$id":"https://iterative.ly/company/77b37977-cb3a-42eb-bce3-09f5f7c3adb7/event/Event%20No%20Properties/version/1.0.0","$schema":"http://json-schema.org/draft-07/schema#","title":"Event No Properties","description":"Event w no properties description","type":"object","properties":{},"additionalProperties":false,"required":[]}',
      'Event Object Types': '{"$id":"https://iterative.ly/company/77b37977-cb3a-42eb-bce3-09f5f7c3adb7/event/Event%20Object%20Types/version/1.0.0","$schema":"http://json-schema.org/draft-07/schema#","title":"Event Object Types","description":"Event with Object and Object Array","type":"object","properties":{"requiredObject":{"description":"Property Object Type","type":"object"},"requiredObjectArray":{"description":"Property Object Array Type","type":"array","items":{"type":"object"}}},"additionalProperties":false,"required":["requiredObject","requiredObjectArray"]}',
      'Event With All Properties': '{"$id":"https://iterative.ly/company/77b37977-cb3a-42eb-bce3-09f5f7c3adb7/event/Event%20With%20All%20Properties/version/1.0.0","$schema":"http://json-schema.org/draft-07/schema#","title":"Event With All Properties","description":"Event w all properties description","type":"object","properties":{"requiredConst":{"description":"Event 2 Property - Const","const":"some-const-value"},"requiredInteger":{"description":"Event 2 Property - Integer    *     * Examples:    * 5, 4, 3","type":"integer"},"optionalString":{"description":"Event 2 Property - Optional String    *     * Examples:    * Some string, or another","type":"string"},"requiredNumber":{"description":"Event 2 Property - Number","type":"number"},"requiredString":{"description":"Event 2 Property - String","type":"string"},"requiredArray":{"description":"Event 2 Property - Array","type":"array","minItems":0,"items":{"type":"string"}},"requiredEnum":{"description":"Event 2 Property - Enum","enum":["Enum1","Enum2"]},"requiredBoolean":{"description":"Event 2 Property - Boolean","type":"boolean"}},"additionalProperties":false,"required":["requiredConst","requiredInteger","requiredNumber","requiredString","requiredArray","requiredEnum","requiredBoolean"]}',
      'Event With Array Types': '{"$id":"https://iterative.ly/company/77b37977-cb3a-42eb-bce3-09f5f7c3adb7/event/Event%20With%20Array%20Types/version/1.0.0","$schema":"http://json-schema.org/draft-07/schema#","title":"Event With Array Types","description":"Description for event with Array Types","type":"object","properties":{"requiredBooleanArray":{"description":"description for required boolean array","type":"array","items":{"type":"boolean"}},"requiredStringArray":{"description":"description for required string array","type":"array","items":{"type":"string"}},"requiredObjectArray":{"description":"Description for required object array","type":"array","items":{"type":"object"}},"requiredNumberArray":{"description":"Description for required number array","type":"array","items":{"type":"number"}}},"additionalProperties":false,"required":["requiredBooleanArray","requiredStringArray","requiredObjectArray","requiredNumberArray"]}',
      'Event With Const Types': '{"$id":"https://iterative.ly/company/77b37977-cb3a-42eb-bce3-09f5f7c3adb7/event/Event%20With%20Const%20Types/version/1.0.0","$schema":"http://json-schema.org/draft-07/schema#","title":"Event With Const Types","description":"Description for event with const types","type":"object","properties":{"Integer Const":{"description":"Description for integer const","const":10},"Boolean Const":{"description":"Description for boolean const type","const":true},"String Int Const":{"description":"Description for string int const","const":0},"Number Const":{"description":"Description for number const","const":2.2},"String Const WIth Quotes":{"description":"Description for Int With Quotes","const":"\\"String \\"Const With\\" Quotes\\""},"String Const":{"description":"Description for string const","const":"String-Constant"}},"additionalProperties":false,"required":["Integer Const","Boolean Const","String Int Const","Number Const","String Const WIth Quotes","String Const"]}',
      'Event With Enum Types': '{"$id":"https://iterative.ly/company/77b37977-cb3a-42eb-bce3-09f5f7c3adb7/event/Event%20With%20Enum%20Types/version/1.0.0","$schema":"http://json-schema.org/draft-07/schema#","title":"Event With Enum Types","description":"Description for event with enum types","type":"object","properties":{"required enum":{"description":"Description for optional enum","enum":["required enum 1","required enum 2"]},"optional enum":{"description":"Description for required enum","enum":["optional enum 1","optional enum 2"]}},"additionalProperties":false,"required":["required enum"]}',
      'Event With Name Enum': '{"$id":"https://iterative.ly/company/77b37977-cb3a-42eb-bce3-09f5f7c3adb7/event/Event%20With%20Name%20Enum/version/1.0.0","$schema":"http://json-schema.org/draft-07/schema#","title":"Event With Name Enum","description":"Has name property to test ObjC codegen","type":"object","properties":{"name":{"description":"Name of the thing","enum":["Firstname","Lastname"]}},"additionalProperties":false,"required":["name"]}',
      'Event With Name Enum 2': '{"$id":"https://iterative.ly/company/77b37977-cb3a-42eb-bce3-09f5f7c3adb7/event/Event%20With%20Name%20Enum%202/version/1.0.0","$schema":"http://json-schema.org/draft-07/schema#","title":"Event With Name Enum 2","description":"","type":"object","properties":{"name":{"description":"","enum":["First2","Lastname"]}},"additionalProperties":false,"required":["name"]}',
      'Event With Name String': '{"$id":"https://iterative.ly/company/77b37977-cb3a-42eb-bce3-09f5f7c3adb7/event/Event%20With%20Name%20String/version/1.0.0","$schema":"http://json-schema.org/draft-07/schema#","title":"Event With Name String","description":"","type":"object","properties":{"name":{"description":"","type":"string"}},"additionalProperties":false,"required":["name"]}',
      'Event With Optional Array Types': '{"$id":"https://iterative.ly/company/77b37977-cb3a-42eb-bce3-09f5f7c3adb7/event/Event%20With%20Optional%20Array%20Types/version/1.0.0","$schema":"http://json-schema.org/draft-07/schema#","title":"Event With Optional Array Types","description":"Description for event with optional array types","type":"object","properties":{"optionalStringArray":{"description":"Description for optional string array","type":"array","items":{"type":"string"}},"optionalJSONArray":{"description":"Description for optional object array","type":"array","items":{"type":"object"}},"optionalBooleanArray":{"description":"Description for optional boolean array","type":"array","items":{"type":"boolean"}},"optionalNumberArray":{"description":"Description for optional number array","type":"array","items":{"type":"number"}}},"additionalProperties":false,"required":[]}',
      'Event With Optional Properties': '{"$id":"https://iterative.ly/company/77b37977-cb3a-42eb-bce3-09f5f7c3adb7/event/Event%20With%20Optional%20Properties/version/1.0.0","$schema":"http://json-schema.org/draft-07/schema#","title":"Event With Optional Properties","description":"Event w optional properties description","type":"object","properties":{"optionalNumber":{"description":"","type":"number"},"optionalArrayString":{"description":"","type":"array","items":{"type":"string"}},"optionalArrayNumber":{"description":"","type":"array","items":{"type":"number"}},"optionalString":{"description":"Optional String property description","type":"string"},"optionalBoolean":{"description":"","type":"boolean"}},"additionalProperties":false,"required":[]}',
      'event withDifferent_CasingTypes': '{"$id":"https://iterative.ly/company/77b37977-cb3a-42eb-bce3-09f5f7c3adb7/event/event%20withDifferent_CasingTypes/version/1.0.0","$schema":"http://json-schema.org/draft-07/schema#","title":"event withDifferent_CasingTypes","description":"Description for case with space","type":"object","properties":{"EnumPascalCase":{"description":"DescirptionForEnumPascalCase","enum":["EnumPascalCase"]},"property with space":{"description":"Description for case with space","type":"string"},"enum with space":{"description":"Description for enum with space","enum":["enum with space"]},"enum_snake_case":{"description":"description_for_enum_snake_case","enum":["enum_snake_case"]},"propertyWithCamelCase":{"description":"descriptionForCamelCase","type":"string"},"PropertyWithPascalCase":{"description":"DescriptionForPascalCase","type":"string"},"property_with_snake_case":{"description":"Description_for_snake_case","type":"string"},"enumCamelCase":{"description":"descriptionForEnumCamelCase","enum":["enumCamelCase"]}},"additionalProperties":false,"required":["EnumPascalCase","property with space","enum with space","enum_snake_case","propertyWithCamelCase","PropertyWithPascalCase","property_with_snake_case","enumCamelCase"]}',
      EventMaxIntForTest: '{"$id":"https://iterative.ly/company/77b37977-cb3a-42eb-bce3-09f5f7c3adb7/event/EventMaxIntForTest/version/1.0.0","$schema":"http://json-schema.org/draft-07/schema#","title":"EventMaxIntForTest","description":"Event to test schema validation","type":"object","properties":{"intMax10":{"description":"property to test schema validation","type":"integer","maximum":10}},"additionalProperties":false,"required":["intMax10"]}'
    }
  end
  # rubocop:enable Layout/LineLength
end
