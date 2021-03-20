# frozen_string_literal: true

##
# Description for event with enum types
#
class EventWithEnumTypes < Itly::Event
  module OptionalEnum
    OPTIONALENUM1 = 'optional enum 1'
    OPTIONALENUM2 = 'optional enum 2'
  end

  module RequiredEnum
    REQUIREDENUM1 = 'required enum 1'
    REQUIREDENUM2 = 'required enum 2'
  end

  ##
  # @param [String] required_enum: Description for optional enum
  # @param [String] optional_enum: Description for required enum
  #
  def initialize(required_num:, optional_enum: nil)
    super(
      name: 'Event With Enum Types',
      properties: {
        'optional enum' => optional_enum,
        'required enum' => required_num
      }.compact,
      id: 'b4fc8366-b05d-40d3-b698-79795701624b',
      version: '1.0.0'
    )
  end
end

##
# Event w no properties description
#
class EventNoProperties < Itly::Event
  def initialize
    super(
      name: 'Event No Properties',
      id: '26af925a-be3a-40e5-947d-33da66a5352f',
      version: '1.0.0'
    )
  end
end

##
# Description for event with const types
#
class EventWithConstTypes < Itly::Event
  def initialize
    super(
      name: 'Event With Const Types',
      properties: {
        'Boolean Const' => true,
        'Integer Const' => 10,
        'Number Const' => 2.2,
        'String Const' => 'String-Constant',
        'String Const WIth Quotes' => '"String "Const With" Quotes"',
        'String Int Const' => 0
      },
      id: '321b8f02-1bb3-4b33-8c21-8c55401d62da',
      version: '1.0.0'
    )
  end
end

##
# Event w optional properties description
#
class EventWithOptionalProperties < Itly::Event
  ##
  # @param [Array] optional_array_number: Property has no description provided in tracking plan.
  # @param [Array] optional_array_string: Property has no description provided in tracking plan.
  # @param [TrueClass/FalseClass] optional_boolean: Property has no description provided in tracking plan.
  # @param [Integer] optional_number: Property has no description provided in tracking plan.
  # @param [String] optional_string: Optional String property description
  #
  def initialize(
    optional_array_number: nil, optional_array_string: nil, optional_boolean: nil,
    optional_number: nil, optional_string: nil
  )
    super(
      name: 'Event With Optional Properties',
      properties: {
        optionalArrayNumber: optional_array_number,
        optionalArrayString: optional_array_string,
        optionalBoolean: optional_boolean,
        optionalNumber: optional_number,
        optionalString: optional_string
      }.compact,
      id: '00b99136-9d1a-48d8-89d5-25f165ff3ae0',
      version: '1.0.0'
    )
  end
end

##
# Description for event with optional array types
#
class EventWithOptionalArrayTypes < Itly::Event
  ##
  # @params [Array] optional_boolean_array: Description for optional boolean array
  # @params [Array] optional_json_array: Description for optional object array
  # @params [Array] optional_number_array: Description for optional number array
  # @params [Array] optional_string_array: Description for optional string array
  #
  def initialize(
    optional_boolean_array: nil, optional_json_array: nil, optional_number_array: nil,
    optional_string_array: nil
  )
    super(
      name: 'Event With Optional Array Types',
      properties: {
        optionalBooleanArray: optional_boolean_array,
        optionalJSONArray: optional_json_array,
        optionalNumberArray: optional_number_array,
        optionalStringArray: optional_string_array
      }.compact,
      id: '2755da0e-a507-4b18-8f17-86d1d5c499ab',
      version: '1.0.0'
    )
  end
end

##
# Event w all properties description
#
class EventWithAllProperties < Itly::Event
  module RequiredEnum
    ENUM1 = 'Enum1'
    ENUM2 = 'Enum2'
  end

  ##
  # @param [Array] required_array: Property type Array
  # @param [TrueClass/FalseClass] required_boolean: Property type Boolean
  # @param [String] required_enum: Property type Enum
  # @param [Integer] required_integer: Property type Integer
  # @param [Numeric] required_number: Property type Number
  # @param [String] required_string: Property type String
  # @param [String] optional_string: Property type Optional String
  # */
  def initialize(
    required_array:, required_boolean:, required_enum:, required_integer:, required_number:,
    required_string:, optional_string: nil
  )
    super(
      name: 'Event With All Properties',
      properties: {
        requiredArray: required_array,
        requiredBoolean: required_boolean,
        requiredEnum: required_enum,
        requiredInteger: required_integer,
        requiredNumber: required_number,
        requiredString: required_string,
        requiredConst: 'some-const-value',
        optionalString: optional_string
      }.compact,
      id: '311ba144-8532-4474-a9bd-8b430625e29a',
      version: '1.0.0'
    )
  end
end

##
# Event to test schema validation
#
class EventMaxIntForTest < Itly::Event
  ##
  # @params [Integer] intMax10: property to test schema validation
  #
  def initialize(int_max10:)
    super(
      name: 'EventMaxIntForTest',
      properties: { intMax10: int_max10 },
      id: 'aa0f08ac-8928-4569-a524-c1699e7da6f4',
      version: '1.0.0'
    )
  end
end

##
# Description for case with space
#
class EventWithDifferentCasingTypes < Itly::Event
  module EnumCamelCase
    ENUMCAMELCASE = 'enumCamelCase'
  end

  module EnumPascalCase
    ENUMPASCALCASE = 'EnumPascalCase'
  end

  module EnumSnakeCase
    ENUMSNAKECASE = 'enum_snake_case'
  end

  module EnumWithSpace
    ENUMWITHSPACE = 'enum with space'
  end

  ##
  # @param [String] enum_camel_case: descriptionForEnumCamelCase
  # @param [String] enum_pascal_case: DescirptionForEnumPascalCase
  # @param [String] enum_snake_case: description_for_enum_snake_case
  # @param [String] enum_with_space: Description for enum with space
  # @param [String] property_with_camel_case: descriptionForCamelCase
  # @param [String] property_with_pascal_case: DescriptionForPascalCase
  # @param [String] property_with_snake_case: Description_for_snake_case
  # @param [String] property_with_space: Description for case with space
  #
  def initialize(
    property_with_camel_case:, property_with_pascal_case:, property_with_snake_case:, property_with_space:,
    enum_camel_case: EventWithDifferentCasingTypes::EnumCamelCase::ENUMCAMELCASE,
    enum_pascal_case: EventWithDifferentCasingTypes::EnumPascalCase::ENUMPASCALCASE,
    enum_snake_case: EventWithDifferentCasingTypes::EnumSnakeCase::ENUMSNAKECASE,
    enum_with_space: EventWithDifferentCasingTypes::EnumWithSpace::ENUMWITHSPACE
  )
    super(
      name: 'event withDifferent_CasingTypes',
      properties: {
        enumCamelCase: enum_camel_case,
        EnumPascalCase: enum_pascal_case,
        enum_snake_case: enum_snake_case,
        'enum with space': enum_with_space,
        propertyWithCamelCase: property_with_camel_case,
        PropertyWithPascalCase: property_with_pascal_case,
        property_with_snake_case: property_with_snake_case,
        'property with space': property_with_space
      },
      id: 'fcb3d82d-208f-4bc2-b8e1-843683d9b595',
      version: '1.0.0'
    )
  end
end
