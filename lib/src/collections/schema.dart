class Schema {
  /// Represents a schema for validating document data.
  ///
  /// A `Schema` defines the structure and constraints for documents within a
  /// collection. It specifies the fields, their data types, whether they are
  /// required, and any additional constraints such as minimum/maximum values or
  /// allowed enum values.
  /// Example
  ///
  /// ```dart
  /// void main() {
  ///   // Define the schema
  ///   final schema = Schema({
  ///     "name": FieldType(type: String, isRequired: true),
  ///     "age": FieldType(type: int, min: 0, max: 120),
  ///     "status": FieldType(type: String, enumValues: ["active", "inactive"]),
  ///   });
  /// ```
  ///
  /// The [fields] parameter is a map where the keys are the field names and
  /// the values are `FieldType` objects defining the field's properties.
  Schema(this.fields);

  /// A map of field names to their corresponding `FieldType` definitions.
  final Map<String, FieldType> fields;

  /// Validates the given [data] against the schema.
  ///
  /// This method checks if the provided [data] conforms to the schema's
  /// definitions. It performs the following validations:
  ///
  /// - Checks if required fields are present.
  /// - Checks if the data types of the fields match the schema's defined types.
  /// - Validates constraints such as minimum/maximum values and allowed enum
  ///   values.
  /// - Executes any custom validators defined in the `FieldType` objects.
  ///
  /// **Throws:**
  /// - `ArgumentError`: If the [data] does not conform to the schema.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final schema = Schema({
  ///   "name": FieldType(type: String, isRequired: true),
  ///   "age": FieldType(type: int, min: 0, max: 120),
  ///   "status": FieldType(type: String, enumValues: ["active", "inactive"]),
  /// });
  ///
  /// final validData = {"name": "Alice", "age": 30, "status": "active"};
  /// schema.validate(validData); // No exception thrown
  ///
  /// final invalidData1 = {"name": "Bob"}; // Missing "age" field
  /// try {
  ///   schema.validate(invalidData1);
  /// } catch (e) {
  ///   print(e); // Prints ArgumentError
  /// }
  ///
  /// final invalidData2 = {"name": "Charlie", "age": "30"}; // Wrong type for "age"
  /// try {
  ///   schema.validate(invalidData2);
  /// } catch (e) {
  ///   print(e); // Prints ArgumentError
  /// }
  /// ```
  void validate(Map<String, dynamic> data) {
    for (final field in fields.keys) {
      final fieldType = fields[field]!;

      // Check if the field is required
      if (!data.containsKey(field) && fieldType.isRequired) {
        throw ArgumentError('Field "$field" is required but not provided.');
      }

      // If the field is NOT provided and NOT required, simply continue to the next field.
      if (!data.containsKey(field) && !fieldType.isRequired) {
        continue; // Skip processing this optional field
      }

      // From here on out, we know the field EXISTS in the data map.
      final value = data[field];

      // Validate type
      if (!fieldType.validateType(value)) {
        throw ArgumentError(
          'Field "$field" should be of type ${fieldType.type}, but got ${value.runtimeType}.',
        );
      }

      // Validate constraints
      fieldType.validateConstraints(value);

      // Custom validator
      if (fieldType.validator != null) {
        fieldType.validator!(value);
      }
    }
  }

  /// Converts an object to a map based on the schema.
  ///
  /// This method takes an object (presumably with a `toJson` method) and
  /// converts it to a map according to the schema. It uses the schema's field
  /// definitions to extract values from the object and handles default values
  /// if a field is missing in the object.
  ///
  /// **Parameters:**
  /// - [obj]: The object to convert. It is assumed to have a `toJson` method
  ///   that returns a map.
  ///
  /// **Returns:**
  /// - A `Map<String, dynamic>` representing the object as a map, with default
  ///   values applied for missing fields.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// class User {
  ///   final String name;
  ///   final int? age;
  ///   User({required this.name, this.age});
  ///   Map<String, dynamic> toJson() => {'name': name, 'age': age};
  /// }
  ///
  /// final schema = Schema({
  ///   "name": FieldType(type: String, isRequired: true),
  ///   "age": FieldType(type: int, defaultValue: 0),
  /// });
  ///
  /// final user = User(name: "Alice");
  /// final userMap = schema.toMap(user);
  /// print(userMap); // Output: {name: Alice, age: 0}
  /// ```
  Map<String, dynamic> toMap(dynamic obj) {
    final result = <String, dynamic>{};
    for (final field in fields.keys) {
      final fieldType = fields[field]!;
      final value =
          obj.toJson()[field]; // Assuming the object has a `toJson` method

      // Handle default values if the value is null
      result[field] = value ?? fieldType.defaultValue;
    }
    return result;
  }
}

/// Defines the properties of a field in a schema.
///
/// A `FieldType` specifies the data type, required status, default value,
/// constraints (min/max, enum values), and custom validator for a field.
class FieldType {
  /// Creates a new `FieldType` instance.
  ///
  /// **Parameters:**
  /// - [type]: The data type of the field (e.g., `String`, `int`, `double`, `bool`).
  /// - [isRequired]: Whether the field is required. Defaults to `false`.
  /// - [defaultValue]: The default value for the field if it is missing.
  /// - [min]: The minimum allowed value for numeric or string length constraints.
  /// - [max]: The maximum allowed value for numeric or string length constraints.
  /// - [enumValues]: A list of allowed values for enum-like fields.
  /// - [validator]: A custom validation function that takes a value and throws
  ///   an exception if the value is invalid.
  FieldType({
    required this.type,
    this.isRequired = false,
    this.defaultValue,
    this.min,
    this.max,
    this.enumValues,
    this.validator,
  });

  /// A custom validation function for the field.
  final void Function(dynamic value)? validator;

  /// The default value for the field if it is missing.
  final dynamic defaultValue;

  /// A list of allowed values for enum-like fields.
  final List<dynamic>? enumValues;

  /// Whether the field is required.
  final bool isRequired;

  /// The minimum allowed value for numeric or string length constraints.
  final num? max;

  /// The maximum allowed value for numeric or string length constraints.
  final num? min;

  /// The data type of the field.
  final Type type;

  /// Validates the type of a field.
  ///
  /// This method checks if the runtime type of the provided [value] matches
  /// the `type` defined in the `FieldType`.
  ///
  /// **Parameters:**
  /// - [value]: The value to validate.
  ///
  /// **Returns:**
  /// - `true` if the type is valid, `false` otherwise.
  ///
  /// **Example:**
  /// ```dart
  /// final fieldType = FieldType(type: String);
  /// print(fieldType.validateType("hello")); // Output: true
  /// print(fieldType.validateType(123)); // Output: false
  /// ```
  bool validateType(dynamic value) {
    return value.runtimeType == type;
  }

  /// Validates constraints like min, max, and enum values.
  ///
  /// This method checks if the provided [value] satisfies the constraints
  /// defined in the `FieldType`, such as minimum/maximum values, string length,
  /// and allowed enum values.
  ///
  /// **Throws:**
  /// - `ArgumentError`: If the [value] does not satisfy the constraints.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final fieldType1 = FieldType(type: int, min: 10, max: 20);
  /// fieldType1.validateConstraints(15); // No exception thrown
  /// try {
  ///   fieldType1.validateConstraints(5); // Throws ArgumentError
  /// } catch (e) {
  ///   print(e);
  /// }
  ///
  /// final fieldType2 = FieldType(type: String, min: 3, max: 5);
  /// fieldType2.validateConstraints("test"); // No exception thrown
  /// try {
  ///   fieldType2.validateConstraints("te"); // Throws ArgumentError
  /// } catch (e) {
  ///   print(e);
  /// }
  /// ```
  void validateConstraints(dynamic value) {
    if (min != null && value is num && value < min!) {
      throw ArgumentError(
          'Value "$value" is less than the minimum allowed: $min.');
    }
    if (max != null && value is num && value > max!) {
      throw ArgumentError('Value "$value" exceeds the maximum allowed: $max.');
    }
    if (enumValues != null && !enumValues!.contains(value)) {
      throw ArgumentError(
        'Value "$value" is not in the allowed values: $enumValues.',
      );
    }
    if (type == String && value is String) {
      if (min != null && value.length < min!) {
        throw ArgumentError('String length of "$value" is less than $min.');
      }
      if (max != null && value.length > max!) {
        throw ArgumentError('String length of "$value" exceeds $max.');
      }
    }
  }
}
