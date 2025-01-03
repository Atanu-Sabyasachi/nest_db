import 'dart:developer';
import 'dart:math' as math;

import 'package:nest_db/nest_db.dart';
import 'package:nest_db/src/collections/document.dart';
import 'package:nest_db/src/db/file_entry.dart';
import 'package:nest_db/src/enums.dart';

/// Manages a collection of documents with a specific schema.
///
/// The `CollectionManager` class is responsible for handling a collection
/// of documents, each adhering to a specified schema. It provides methods
/// for managing and interacting with the documents within the collection.
///
/// Example usage:
/// ```dart
/// final schema = Schema(...);
/// final collectionManager = CollectionManager('MyCollection', schema);
/// collectionManager.addDocument('doc1', {'field1': 'value1', 'field2': 42});
/// ```
///
class CollectionManager {
  CollectionManager(
    this.name,
    this._documents,
    this.schema,
  );

  /// Properties:
  /// - `name`: The name of the collection.
  final String name;

  /// - `schema`: The schema that defines the structure of the documents in the collection.
  final Schema schema;

  /// - `_documents`: A private map storing the documents, where each document is identified by a unique string key.
  final Map<String, Map<String, dynamic>> _documents;

  final Nest _nest = Nest();

  /// Writes a new document to the collection or updates an existing document.
  ///
  /// This method performs the following tasks:
  /// 1. Validates the provided `data` against the collection's `schema` to ensure data integrity.
  /// 2. Checks if a document with the provided `id` already exists in the internal `_documents` map:
  ///    - If the document exists, it's considered an update operation.
  ///    - If the document doesn't exist, it's considered a new document creation.
  /// 3. Creates a `FileEntry` object to manage timestamps:
  ///    - For existing documents, it retrieves the existing `createdAt` from the document data (if available) and sets the `updatedAt` to the current date/time.
  ///    - For new documents, it sets both `createdAt` and `updatedAt` to the current date/time.
  /// 4. Logs the created `FileEntry` object for debugging purposes.
  /// 5. Adds the `createdAt` and `updatedAt` fields to the `data` using the `FileEntry` object's timestamps.
  /// 6. Saves the data to the collection by updating the `_documents` map with the `id` as the key and the updated data (including timestamps) as the value.
  /// 7. Notifies any registered reactive listeners about the write operation, providing details like the `id` and `data`.
  /// 8. Calls the `_nest.saveCollectionToDisk(name)` method (presumably implemented elsewhere) to persist the updated collection data to disk.
  ///
  /// This method essentially handles both document creation and updates in a single method, differentiating based on the existence of the document with the provided `id`. It also manages timestamps for both scenarios.
  ///
  /// Parameters:
  ///   - [id]: The unique identifier for the document.
  ///   - [data]: A map representing the document's data.
  ///
  /// Throws:
  ///   - [ArgumentError]: If the provided `data` does not conform to the collection's [schema].
  ///
  /// Example:
  /// ```dart
  /// final data = {'name': 'John Doe', 'age': 30};
  /// await collectionManager.write('user123', data); // Create new document
  ///
  /// // Update existing document
  /// data['age'] = 31;
  /// await collectionManager.write('user123', data);
  /// ```
  Future<void> write(String id, Map<String, dynamic> data) async {
    // Validate the schema for the incoming data
    schema.validate(data);

    // Check if the document already exists
    final existingDocument = _documents[id];
    final now = DateTime.now();

    FileEntry fileEntry;

    if (existingDocument != null) {
      //* UPDATE
      // For existing documents, keep the original 'createdAt' and update 'updatedAt'
      final createdAt = DateTime.parse(existingDocument['createdAt']);
      fileEntry = FileEntry(
        key: id,
        createdAt: createdAt,
        updatedAt: now,
      );
    } else {
      //* ADD
      // For new documents, set both 'createdAt' and 'updatedAt' to now
      fileEntry = FileEntry(
        key: id,
        createdAt: now,
        updatedAt: now,
      );
    }
    log('fileEntry: $fileEntry');
    // Add timestamp fields to the data
    data['createdAt'] = fileEntry.createdAt.toIso8601String();
    data['updatedAt'] = fileEntry.updatedAt.toIso8601String();

    // Save the updated document to the collection
    _documents[id] = data;

    // Notify reactive listeners about the change
    _nest.notifyReactive(name, {'type': 'write', 'id': id, 'data': data});

    // Persist the collection to disk
    await _nest.saveCollectionToDisk(name);
  }

  /// Retrieves a document from the collection by its ID.
  ///
  /// Example:
  /// ```dart
  /// final document = collectionManager.read('user123');
  /// if (document != null) {
  ///   print(document['name']);
  /// } else {
  ///   print('Document not found.');
  /// }
  /// ```
  ///
  /// Parameters:
  ///   - [id]: The unique identifier of the document to retrieve.
  ///
  /// Returns:
  ///   A [Map<String, dynamic>] representing the document's data if found,
  ///   or `null` if the document with the given [id] does not exist in the collection.
  Map<String, dynamic>? read(String id) {
    return _documents[id];
  }

  /// Updates an existing document in the collection.
  ///
  /// This method attempts to update the document with the given `id` using the provided `updatedData`.
  /// It performs the following steps:
  /// 1. Checks if a document with the provided `id` exists in the internal `_documents` map.
  ///    - If the document doesn't exist, throws an `Exception` with a message indicating the missing document.
  /// 2. Retrieves the existing document data from the `_documents` map.
  /// 3. Creates a `FileEntry` object using the `id` and optionally existing `createdAt` timestamp from the existing data (or the current date/time if `createdAt` is missing).
  ///    - The `FileEntry` object also sets the `updatedAt` timestamp to the current date/time.
  /// 4. Merges the existing document data with the provided `updatedData` using the spread operator (`...`).
  /// 5. Updates the `createdAt` and `updatedAt` fields in the merged data:
  ///    - `createdAt` is always preserved from the existing data or set to the initial creation time.
  ///    - `updatedAt` is updated to the current date/time to reflect the modification.
  /// 6. Validates the merged data against the collection's `schema` to ensure data integrity.
  /// 7. Updates the document in the internal `_documents` map with the validated merged data.
  /// 8. Notifies any registered reactive listeners about the update operation, providing details like the `id` and updated `data`.
  /// 9. Calls the `_nest.saveCollectionToDisk(name)` method (presumably implemented elsewhere) to persist the updated collection data to disk.
  ///
  /// This method essentially modifies an existing document with the provided data, validates it against the schema, updates timestamps, and triggers notifications and data persistence.
  ///
  /// Parameters:
  ///   - [id]: The unique identifier of the document to update.
  ///   - [updatedData]: A map containing the updated data for the document.
  ///
  /// Throws:
  ///   - [Exception]: If the document with the provided `id` does not exist.
  ///   - [ArgumentError] (potentially): Thrown internally by the `schema.validate` method if the merged data violates the schema (only if the document exists).
  ///
  /// Example:
  /// ```dart
  /// final newData = {'name': 'Jane Doe', 'age': 31};
  /// await collectionManager.update('user123', newData);
  ///
  /// // Example where document doesn't exist (throws Exception):
  /// await collectionManager.update('nonExistentId', {'field': 'value'});
  /// ```

  Future<void> update(String id, Map<String, dynamic> updatedData) async {
    if (!_documents.containsKey(id)) {
      throw Exception("Document with id '$id' does not exist.");
    }

    // Retrieve the existing document
    final existingData = _documents[id]!;

    // Extract or initialize timestamps using FileEntry
    final fileEntry = FileEntry.fromMap({
      'key': id,
      'createdAt':
          existingData['createdAt'] ?? DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    log('fileEntry: $fileEntry');

    // Merge existing data with the updated data
    final mergedData = {...existingData, ...updatedData};

    // Add or update the `createdAt` and `updatedAt` fields
    mergedData['createdAt'] =
        fileEntry.createdAt.toIso8601String(); // Always preserve createdAt
    mergedData['updatedAt'] =
        fileEntry.updatedAt.toIso8601String(); // Update updatedAt

    // Validate against schema
    schema.validate(mergedData);

    // Update the document in memory
    _documents[id] = mergedData;

    // Notify listeners and save the collection to disk
    _nest
        .notifyReactive(name, {'type': 'update', 'id': id, 'data': mergedData});
    await _nest.saveCollectionToDisk(name);
  }

  /// Deletes a document from the collection by its ID.
  ///
  /// This method removes the document with the given [id] from the collection.
  /// It first checks if a document with the given [id] exists. If it does, it
  /// removes the document, notifies any reactive listeners, and persists the
  /// collection to disk. If a document with the given [id] does not exist,
  /// this method does nothing.
  ///
  /// Example:
  /// ```dart
  /// await collectionManager.delete('user123');
  ///
  /// // Example where document doesn't exist (no action taken):
  /// await collectionManager.delete('nonExistentId');
  /// ```
  ///
  /// Parameters:
  ///   - [id]: The unique identifier of the document to delete.
  Future<void> delete(String id) async {
    if (_documents.containsKey(id)) {
      _documents.remove(id);
      _nest.notifyReactive(name, {'type': 'delete', 'id': id});
      await Nest().saveCollectionToDisk(name);
    }
  }

  /// Queries the collection for documents that satisfy a given condition.
  ///
  /// This method iterates through all documents in the collection and applies
  /// the provided [condition] function to each document wrapped in a [Document] object.
  /// It returns a list of documents that satisfy the condition.
  ///
  /// Example:
  /// ```dart
  /// final results = collectionManager.query((doc) => doc.name == 'John' && doc.age > 25);
  ///
  /// // Example with a simpler condition
  /// final allUsers = collectionManager.query((doc) => true); // Returns all documents
  /// ```
  ///
  /// Parameters:
  ///   - [condition]: A function that takes a [Document] object as input and
  ///     returns `true` if the document satisfies the query condition, and `false` otherwise.
  ///
  /// Returns:
  ///   A [List<Map<String, dynamic>>] containing the documents that satisfy the
  ///   provided [condition]. Returns an empty list if no documents match the condition.
  List<Map<String, dynamic>> query(bool Function(Document doc) condition) {
    return _documents.entries
        .where((entry) => condition(Document(entry.key, entry.value)))
        .map((entry) => {"id": entry.key, ...entry.value})
        .toList();
  }

  /// Converts the internal `_documents` map to a `Map<String, dynamic>` format.
  ///
  /// This method provides a complete representation of all stored documents
  /// in their current state as a single map. The keys of the map represent the
  /// unique document IDs, and the values are the corresponding document data.
  ///
  /// ### Example
  /// ```dart
  /// // Assume _documents contains:
  /// // {
  /// //   "1": {"name": "Alice", "age": 25},
  /// //   "2": {"name": "Bob", "age": 30}
  /// // }
  ///
  /// final result = toMap();
  /// print(result);
  /// // Output:
  /// // {
  /// //   "1": {"name": "Alice", "age": 25},
  /// //   "2": {"name": "Bob", "age": 30}
  /// // }
  /// ```
  ///
  /// ### Returns
  /// A `Map<String, dynamic>` where:
  /// - The key is the document ID.
  /// - The value is the document data.
  Map<String, dynamic> toMap() {
    return _documents;
  }

  /// Filters and returns a list of entries where the value of a specified field
  /// falls within a given numerical range (inclusive).
  ///
  /// This method is useful for querying data within a specific range of numbers
  /// for a given field.
  ///
  /// ### Parameters
  /// - `fieldName` (`String`): The key of the field to evaluate.
  /// - `min` (`num`): The minimum value of the range (inclusive).
  /// - `max` (`num`): The maximum value of the range (inclusive).
  ///
  /// ### Returns
  /// A list of maps where:
  /// - The value of the specified `fieldName` falls within the range `[min, max]`.
  /// - Entries are excluded if the field's value is not numerical or not present.
  ///
  /// ### Example
  /// ```dart
  /// // Assume _documents contains:
  ///  {
  ///    "1": {"age": 25, "name": "Alice"},
  ///    "2": {"age": 30, "name": "Bob"},
  ///    "3": {"age": 20, "name": "Charlie"}
  ///  }
  ///
  /// final result = rangeQuery("age", 21, 30);
  /// print(result);
  /// // Output:
  ///  [
  ///    {"age": 25, "name": "Alice"},
  ///    {"age": 30, "name": "Bob"}
  ///  ]
  /// ```
  ///
  /// ### Notes
  /// - The field's value must be a numerical type (`num`) for inclusion.
  /// - Non-numeric or missing values for `fieldName` are ignored.
  List<Map<String, dynamic>> rangeQuery(String fieldName, num min, num max) {
    return _documents.entries
        .where((entry) {
          final value = entry.value[fieldName];
          return value is num && value >= min && value <= max;
        })
        .map((entry) => entry.value)
        .toList();
  }

  /// Filters entries where a specified field contains the given substring (case-insensitive).
  ///
  /// This method searches for entries in the collection where the value of the
  /// specified [fieldName] contains the given [substring]. The comparison is
  /// performed in a case-insensitive manner. If the field's value is `null` or
  /// not a string, the entry is excluded from the results.
  ///
  /// Example:
  /// ```dart
  /// // Example collection:
  ///  {
  ///    "1": {"name": "Alice Wonderland", "age": 25},
  ///    "2": {"name": "Bob Marley", "age": 30},
  ///    "3": {"name": "Charlie Brown", "age": 20}
  ///  }
  ///
  /// final results = substringQuery("name", "ar");
  /// print(results);
  /// // Output:
  ///  [
  ///    {"name": "Bob Marley", "age": 30}
  ///    {"name": "Charlie Brown", "age": 20}
  ///  ]
  /// ```
  ///
  /// Parameters:
  ///   - [fieldName]: The key of the field to evaluate in each entry.
  ///   - [substring]: The substring to search for (case-insensitive).
  ///
  /// Returns:
  ///   A list of maps where the value of [fieldName] contains the [substring].
  ///
  /// Notes:
  ///   - The value of [fieldName] is converted to a string and matched
  ///     in lowercase for case-insensitivity.
  ///   - Entries with `null` or non-string values for the [fieldName] are excluded.
  List<Map<String, dynamic>> substringQuery(
      String fieldName, String substring) {
    return _documents.entries
        .where((entry) =>
            entry.value[fieldName]
                ?.toString()
                .toLowerCase()
                .contains(substring.toLowerCase()) ??
            false)
        .map((entry) => entry.value)
        .toList();
  }

  /// Filters entries in the collection based on a regular expression pattern.
  ///
  /// This method searches for all entries where the value of the specified [fieldName]
  /// matches the provided [pattern]. The field's value is converted to a string for matching.
  /// If the field is `null` or does not exist, the entry is ignored.
  ///
  /// Example:
  /// ```dart
  /// // Example dataset:
  ///  {
  ///    "1": {"name": "Alice Wonderland", "age": 25},
  ///    "2": {"name": "Bob Marley", "age": 30},
  ///    "3": {"name": "Charlie Brown", "age": 20}
  ///  }
  ///
  /// final pattern = RegExp(r'Bob|Alice');
  /// final results = regexQuery('name', pattern);
  /// print(results);
  /// // Output:
  ///  [
  ///    {"name": "Alice Wonderland", "age": 25},
  ///    {"name": "Bob Marley", "age": 30}
  ///  ]
  /// ```
  ///
  /// Parameters:
  ///   - [fieldName]: The name of the field to apply the regex pattern.
  ///   - [pattern]: A `RegExp` object representing the regex pattern to match.
  ///
  /// Returns:
  ///   A list of entries where the value of the specified [fieldName]
  ///   matches the given regex pattern.
  List<Map<String, dynamic>> regexQuery(String fieldName, RegExp pattern) {
    return _documents.entries
        .where((entry) =>
            entry.value[fieldName]?.toString().contains(pattern) ?? false)
        .map((entry) => entry.value)
        .toList();
  }

  /// Performs a compound query on the collection using AND, OR, and NOT conditions.
  ///
  /// This method allows for complex filtering of documents by combining
  /// multiple conditions using logical AND, OR, and NOT operators. It evaluates
  /// each document against the provided conditions and returns a list of
  /// documents that satisfy the combined logic.
  ///
  /// Example:
  /// ```dart
  /// final documents = {
  ///   "1": {"name": "Alice", "age": 25, "city": "New York"},
  ///   "2": {"name": "Bob", "age": 30, "city": "Los Angeles"},
  ///   "3": {"name": "Charlie", "age": 20, "city": "New York"},
  ///   "4": {"name": "David", "age": 35, "city": "Chicago"},
  /// };
  /// final schema = Schema({}); // Dummy schema for the example
  /// final collectionManager = CollectionManager('users', documents, schema);
  ///
  /// final results = collectionManager.compoundQuery(
  ///   andConditions: [
  ///     (doc) => doc['age'] > 20,
  ///     (doc) => doc['city'] == 'New York',
  ///   ],
  ///   orConditions: [
  ///     (doc) => doc['name'] == 'Bob',
  ///   ],
  ///   notConditions: [
  ///     (doc) => doc['age'] > 30,
  ///   ],
  /// );
  /// print(results);
  /// // Output:
  ///  [{name: Alice, age: 25, city: New York}]
  /// ```
  ///
  /// Parameters:
  ///   - [andConditions]: A list of functions that must *all* return `true` for a
  ///     document to be included (logical AND). Defaults to an empty list.
  ///   - [orConditions]: A list of functions where *at least one* must return
  ///     `true` for a document to be included (logical OR). Defaults to an empty list.
  ///   - [notConditions]: A list of functions that must *all* return `false` for
  ///     a document to be included (logical NOT). Defaults to an empty list.
  ///
  /// Returns:
  ///   A list of maps representing the documents that satisfy the combined
  ///   conditions. Returns an empty list if no documents match.
  List<Map<String, dynamic>> compoundQuery({
    List<bool Function(Map<String, dynamic> doc)> andConditions = const [],
    List<bool Function(Map<String, dynamic> doc)> orConditions = const [],
    List<bool Function(Map<String, dynamic> doc)> notConditions = const [],
  }) {
    return _documents.entries
        .where((entry) {
          final doc = entry.value;
          final andCheck = andConditions.isEmpty ||
              andConditions.every((condition) => condition(doc));
          final orCheck = orConditions.isEmpty ||
              orConditions.any((condition) => condition(doc));
          final notCheck = notConditions.isEmpty ||
              notConditions.every((condition) => !condition(doc));
          return andCheck && orCheck && notCheck;
        })
        .map((entry) => entry.value)
        .toList();
  }

  // List<Map<String, dynamic>> advancedQuery({
  //   List<bool Function(Map<String, dynamic>)> andConditions = const [],
  //   List<bool Function(Map<String, dynamic>)> orConditions = const [],
  //   List<bool Function(Map<String, dynamic>)> notConditions = const [],
  // }) {
  //   return _documents.entries
  //       .where((entry) {
  //         final doc = {"id": entry.key, ...entry.value};
  //         final andCheck = andConditions.isEmpty ||
  //             andConditions.every((condition) => condition(doc));
  //         final orCheck = orConditions.isEmpty ||
  //             orConditions.any((condition) => condition(doc));
  //         final notCheck = notConditions.isEmpty ||
  //             notConditions.every((condition) => !condition(doc));
  //         return andCheck && orCheck && notCheck;
  //       })
  //       .map((entry) => {"id": entry.key, ...entry.value})
  //       .toList();
  // }

  /// Performs a full-text search on the collection for a given keyword.
  ///
  /// This method searches for documents containing the specified [keyword] within
  /// their fields. The search is case-insensitive. You can optionally specify
  /// the [fields] to search within; if no fields are provided, the search is
  /// performed across all fields of each document.
  ///
  /// Example:
  /// ```dart
  /// final documents = {
  ///   "1": {"name": "Alice Wonderland", "description": "A curious girl."},
  ///   "2": {"name": "Bob the Builder", "description": "Can we fix it?"},
  ///   "3": {"name": "Charlie Brown", "description": "Good grief!"},
  ///   "4": {"name": "David", "description": null}, // Example with null description
  /// };
  /// final schema = Schema({}); // Dummy schema for the example
  /// final collectionManager = CollectionManager('items', documents, schema);
  ///
  /// // Search across all fields for "builder"
  /// final results1 = collectionManager.fullTextSearch("builder");
  /// print(results1);
  /// // Output:
  ///  [{name: Bob the Builder, description: Can we fix it?}]
  ///
  /// // Search within the "name" field for "Alice"
  /// final results2 = collectionManager.fullTextSearch("Alice", fields: ["name"]);
  /// print(results2);
  /// // Output:
  ///  [{name: Alice Wonderland, description: A curious girl.}]
  ///
  /// // Search within the "description" field for "grief"
  /// final results3 = collectionManager.fullTextSearch("grief", fields: ["description"]);
  /// print(results3);
  /// // Output:
  ///  [{name: Charlie Brown, description: Good grief!}]
  ///
  /// // Search with a null field
  /// final results4 = collectionManager.fullTextSearch("David", fields: ["name"]);
  /// print(results4);
  /// // Output:
  ///  [{name: David, description: null}]
  /// ```
  ///
  /// Parameters:
  ///   - [keyword]: The keyword to search for (case-insensitive).
  ///   - [fields]: An optional list of field names to search within. If empty,
  ///     all fields are searched. Defaults to an empty list.
  ///
  /// Returns:
  ///   A list of maps representing the documents that contain the keyword in
  ///   the specified fields (or all fields if none are specified). Returns an
  ///   empty list if no documents match.
  List<Map<String, dynamic>> fullTextSearch(
    String keyword, {
    List<String> fields = const [],
  }) {
    return _documents.entries
        .where((entry) {
          final doc = entry.value;
          return (fields.isEmpty ? doc.keys : fields).any((field) =>
              doc[field]
                  ?.toString()
                  .toLowerCase()
                  .contains(keyword.toLowerCase()) ??
              false);
        })
        .map((entry) => entry.value)
        .toList();
  }

  /// Filters entries where a specified numerical field is within a given proximity to a value.
  ///
  /// This method searches for documents where the value of the specified
  /// [fieldName] is within the given [threshold] of the provided [value].
  /// The comparison is based on the absolute difference between the field's
  /// value and the target [value]. Only documents where the field's value is a
  /// `num` type are considered.
  ///
  /// Example:
  /// ```dart
  /// final documents = {
  ///   "1": {"product_id": 1001, "price": 95},
  ///   "2": {"product_id": 1002, "price": 100},
  ///   "3": {"product_id": 1003, "price": 105},
  ///   "4": {"product_id": 1004, "price": "not a number"},
  /// };
  /// final schema = Schema({}); // Dummy schema for the example
  /// final collectionManager = CollectionManager('products', documents, schema);
  ///
  /// // Find products with a price within 5 of 100
  /// final results = collectionManager.proximitySearch("price", 100, 5);
  /// print(results);
  /// // Output:
  ///  [{product_id: 1001, price: 95}, {product_id: 1002, price: 100}, {product_id: 1003, price: 105}]
  ///
  /// // Find products with price within 2 of 100
  /// final results2 = collectionManager.proximitySearch("price", 100, 2);
  /// print(results2);
  /// // Output:
  ///  [{product_id: 1002, price: 100}, {product_id: 1003, price: 105}]
  ///
  /// // Example with non-num value
  /// final results3 = collectionManager.proximitySearch("price", 100, 5);
  /// print(results3);
  /// // Output:
  ///  [{product_id: 1001, price: 95}, {product_id: 1002, price: 100}, {product_id: 1003, price: 105}]
  /// ```
  ///
  /// Parameters:
  ///   - [fieldName]: The name of the numerical field to compare.
  ///   - [value]: The target value for the proximity search.
  ///   - [threshold]: The maximum absolute difference allowed between the
  ///     field's value and the target value.
  ///
  /// Returns:
  ///   A list of maps representing the documents where the specified field's
  ///   value is within the given threshold of the target value. Returns an
  ///   empty list if no documents match or if the field is not a number.
  List<Map<String, dynamic>> proximitySearch(
      String fieldName, num value, num threshold) {
    return _documents.entries
        .where((entry) {
          final fieldValue = entry.value[fieldName];
          return fieldValue is num && (fieldValue - value).abs() <= threshold;
        })
        .map((entry) => entry.value)
        .toList();
  }

  /// Searches for documents where a specified field matches a given value, using a default if the field is missing.
  ///
  /// This method searches for documents where the value of the specified
  /// [fieldName] is equal to the provided [value]. If a document does not
  /// contain the [fieldName], the [defaultValue] is used for comparison. This
  /// allows for searching based on a fallback value when a field is absent.
  ///
  /// Example:
  /// ```dart
  /// final documents = {
  ///   "1": {"name": "Alice", "age": 25},
  ///   "2": {"name": "Bob"}, // Missing "age" field
  ///   "3": {"name": "Charlie", "age": 30},
  /// };
  /// final schema = Schema({}); // Dummy schema for the example
  /// final collectionManager = CollectionManager('users', documents, schema);
  ///
  /// // Find users with age 25
  /// final results1 = collectionManager.searchWithDefault("age", 25, 0);
  /// print(results1);
  /// // Output:
  ///  [{name: Alice, age: 25}]
  ///
  /// // Find users with age 0 (using default)
  /// final results2 = collectionManager.searchWithDefault("age", 0, 0);
  /// print(results2);
  /// // Output:
  ///  [{name: Bob}]
  ///
  /// // Find users with age 30
  /// final results3 = collectionManager.searchWithDefault("age", 30, 0);
  /// print(results3);
  /// // Output:
  ///  [{name: Charlie, age: 30}]
  ///
  /// //Find users with name bob (case sensitive)
  /// final results4 = collectionManager.searchWithDefault("name", "Bob", "");
  /// print(results4);
  /// // Output:
  ///  [{name: Bob}]
  /// ```
  ///
  /// Parameters:
  ///   - [fieldName]: The name of the field to compare.
  ///   - [value]: The value to search for.
  ///   - [defaultValue]: The default value to use if the field is missing in a document.
  ///
  /// Returns:
  ///   A list of maps representing the documents where the specified field's
  ///   value (or the default value if the field is missing) matches the provided
  ///   value. Returns an empty list if no documents match.
  List<Map<String, dynamic>> searchWithDefault(
      String fieldName, dynamic value, dynamic defaultValue) {
    return _documents.entries
        .where((entry) => (entry.value[fieldName] ?? defaultValue) == value)
        .map((entry) => entry.value)
        .toList();
  }

  /// Sorts entries in the collection based on specified field names and options.
  ///
  /// This method allows you to sort documents within the collection based on the
  /// values of one or more fields. You can specify the order (ascending or
  /// descending) and optionally include the document IDs in the returned list.
  ///
  /// **Sorting Logic:**
  /// - The sorting is performed by iterating through the provided `fieldNames`.
  /// - For each field, the corresponding values from two documents are compared.
  /// - Null values are considered "less than" non-null values.
  /// - If both values are comparable types (e.g., numbers, strings), the
  ///   comparison is based on their natural order using the `compareTo` method.
  /// - If two documents have the same value for all specified fields, their
  ///   relative order remains unchanged.
  ///
  /// **Parameters:**
  /// - [fieldNames]: A required list of strings representing the field names to
  ///   use for sorting. Documents are compared based on these fields in the
  ///   order they appear in the list.
  /// - [ascending]: A boolean flag indicating the sorting order. Defaults to
  ///   `true` (ascending order).
  /// - [includeId]: A boolean flag indicating whether to include the document ID
  ///   in the returned map objects. Defaults to `false`.
  ///
  /// **Returns:**
  /// - A list of maps representing the sorted documents. If [includeId] is
  ///   `true`, each map includes an "id" key. Returns an empty list if the
  ///   collection is empty.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final documents = {
  ///   "1": {"name": "Charlie", "age": 20, "city": "London"},
  ///   "2": {"name": "Alice", "age": 25, "city": "New York"},
  ///   "3": {"name": "Bob", "age": 30, "city": "Paris"},
  ///   "4": {"name": "David", "city": "Tokyo"}, // Missing age
  ///   "5": {"name": "Eve", "age": 25, "city": "Berlin"},
  /// };
  /// final schema = Schema({}); // Dummy schema for the example
  /// final collectionManager = CollectionManager('users', documents, schema);
  ///
  /// // Sort by age (ascending)
  /// final sortedByAge = collectionManager.sortDocs(fieldNames: ["age"]);
  /// print(sortedByAge);
  /// // Output:
  ///  [{name: Charlie, age: 20, city: London}, {name: Alice, age: 25, city: New York}, {name: Eve, age: 25, city: Berlin}, {name: Bob, age: 30, city: Paris}, {name: David, city: Tokyo}]
  ///
  /// // Sort by name (descending) including IDs
  /// final sortedByNameDescendingWithIds = collectionManager.sortDocs(
  ///   fieldNames: ["name"],
  ///   ascending: false,
  ///   includeId: true,
  /// );
  /// print(sortedByNameDescendingWithIds);
  /// // Output:
  ///  [{id: 1, name: Alice, age: 25, city: New York}, {id: 3, name: Bob, age: 30, city: Paris}, {id: 4, name: David, city: Tokyo}, {id: 5, name: Eve, age: 25, city: Berlin}, {id: 2, name: Charlie, age: 20, city: London}]
  ///
  /// // Sort by city then age (ascending)
  /// final sortedByCityAge = collectionManager.sortDocs(fieldNames: ["city", "age"]);
  /// print(sortedByCityAge);
  /// // Output:
  ///  [{name: Eve, age: 25, city: Berlin}, {name: Charlie, age: 20, city: London}, {name: Bob, age: 30, city: Paris}, {name: Alice, age: 25, city: New York}, {name: David, city: Tokyo}]
  /// ```
  List<Map<String, dynamic>> sortDocs({
    required List<String> fieldNames,
    bool ascending = true,
    bool includeId = false,
  }) {
    final entries = _documents.entries.toList();
    entries.sort((a, b) {
      for (final fieldName in fieldNames) {
        final valueA = a.value[fieldName];
        final valueB = b.value[fieldName];

        // Handle nulls
        if (valueA == null && valueB != null) {
          return ascending ? -1 : 1;
        } else if (valueA != null && valueB == null) {
          return ascending ? 1 : -1;
        }

        // Compare if both are comparable
        if (valueA is Comparable && valueB is Comparable) {
          final comparison =
              ascending ? valueA.compareTo(valueB) : valueB.compareTo(valueA);
          if (comparison != 0) return comparison;
        }
      }
      return 0; // No differences found for any field
    });

    // Map the result, optionally including the ID
    return entries.map((entry) {
      return includeId ? {"id": entry.key, ...entry.value} : entry.value;
    }).toList();
  }

  /// Retrieves a paginated subset of documents from the collection.
  ///
  /// This method allows you to retrieve documents in pages, which is useful
  /// for handling large collections efficiently. It returns a subset of
  /// documents based on the provided [page] number and [limit].
  ///
  /// **Boundary Conditions:**
  /// - If [startIndex] is negative, it's set to 0 to avoid errors.
  /// - If [startIndex] is greater than or equal to the number of documents, an
  ///   empty list is returned.
  /// - The [endIndex] is capped at the number of documents to prevent
  ///   `RangeError` if `startIndex + limit` exceeds the collection size.
  ///
  /// **Parameters:**
  /// - [page]: The page number to retrieve (1-based index). Must be a positive integer.
  /// - [limit]: The number of documents to include in each page. Must be a positive integer.
  ///
  /// **Returns:**
  /// - A list of maps representing the documents on the specified page.
  ///   Returns an empty list if the page is out of range (e.g., if the collection
  ///   is empty or the [page] number is too high).
  ///
  /// **Throws:**
  /// - [ArgumentError]: If [page] or [limit] are not positive integers.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final documents = {
  ///   "1": {"name": "Alice"},
  ///   "2": {"name": "Bob"},
  ///   "3": {"name": "Charlie"},
  ///   "4": {"name": "David"},
  ///   "5": {"name": "Eve"},
  /// };
  /// final schema = Schema({}); // Dummy schema for the example
  /// final collectionManager = CollectionManager('users', documents, schema);
  ///
  /// // Get the first page (page 1) with a page size of 2
  /// final page1 = collectionManager.paginate(page: 1, limit: 2);
  /// print(page1);
  /// // Output:
  /// // [{name: Alice}, {name: Bob}]
  ///
  /// // Get the second page (page 2) with a page size of 2
  /// final page2 = collectionManager.paginate(page: 2, limit: 2);
  /// print(page2);
  /// // Output:
  /// // [{name: Charlie}, {name: David}]
  ///
  /// // Get the third page (page 3) with a page size of 2
  /// final page3 = collectionManager.paginate(page: 3, limit: 2);
  /// print(page3);
  /// // Output:
  /// // [{name: Eve}]
  ///
  /// // Get a page that is out of range
  /// final page4 = collectionManager.paginate(page: 4, limit: 2);
  /// print(page4);
  /// // Output:
  /// // []
  ///
  /// //Invalid arguments
  /// try {
  ///   collectionManager.paginate(page: -1, limit: 2);
  /// } catch (e) {
  ///   print(e); // Output: Invalid argument(s)
  /// }
  /// try {
  ///   collectionManager.paginate(page: 1, limit: -2);
  /// } catch (e) {
  ///   print(e); // Output: Invalid argument(s)
  /// }
  /// ```
  List<Map<String, dynamic>> paginate({required int page, required int limit}) {
    if (page <= 0 || limit <= 0) {
      throw ArgumentError('Page and pagr limit must be positive integers.');
    }
    int startIndex = (page - 1) * limit;
    if (startIndex < 0) startIndex = 0; // Avoid negative start index
    if (startIndex >= _documents.length) return [];
    final endIndex = startIndex + limit < _documents.length
        ? startIndex + limit
        : _documents.length;
    return _documents.entries
        .toList()
        .sublist(startIndex, endIndex)
        .map((entry) => entry.value)
        .toList();
  }

  /// Groups documents in the collection based on the value of a specified field.
  ///
  /// This method iterates through the documents and groups them based on the
  /// value of the provided [fieldName]. It creates a map where the keys are the
  /// unique values of the field and the values are lists of documents that
  /// have that value for the field.
  ///
  /// **Handling Null or Missing Fields:**
  /// Documents where the specified [fieldName] is `null` or missing will be
  /// grouped under a `null` key in the resulting map.
  ///
  /// **Parameters:**
  /// - [fieldName]: The name of the field to group the documents by.
  ///
  /// **Returns:**
  /// - A `Map<dynamic, List<Map<String, dynamic>>>` where:
  ///   - The keys are the unique values of the [fieldName] (or `null` for
  ///     documents with a missing or `null` field).
  ///   - The values are lists of maps, where each map represents a document
  ///     that has the corresponding key value for the [fieldName].
  ///   Returns an empty map if the collection is empty.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final documents = {
  ///   "1": {"city": "New York", "name": "Alice"},
  ///   "2": {"city": "Los Angeles", "name": "Bob"},
  ///   "3": {"city": "New York", "name": "Charlie"},
  ///   "4": {"name": "David"}, // Missing "city" field
  ///   "5": {"city": null, "name": "Eve"}, // Null "city" field
  /// };
  /// final schema = Schema({}); // Dummy schema for the example
  /// final collectionManager = CollectionManager('users', documents, schema);
  ///
  /// final groupedByCity = collectionManager.groupBy("city");
  /// print(groupedByCity);
  ///
  /// // Output:
  ///  {
  ///    New York: [{city: New York, name: Alice}, {city: New York, name: Charlie}],
  ///    Los Angeles: [{city: Los Angeles, name: Bob}],
  ///    null: [{name: David}, {city: null, name: Eve}]
  ///  }
  ///
  /// //Example with empty documents
  /// final emptyDocuments = {};
  /// final emptyCollectionManager = CollectionManager('users', emptyDocuments, schema);
  /// final emptyGroupedByCity = emptyCollectionManager.groupBy("city");
  /// print(emptyGroupedByCity);
  ///
  /// // Output
  /// {}
  /// ```
  Map<dynamic, List<Map<String, dynamic>>> groupBy(String fieldName) {
    final groups = <dynamic, List<Map<String, dynamic>>>{};
    _documents.forEach((key, value) {
      final groupKey = value[fieldName];
      groups.putIfAbsent(groupKey, () => []).add(value);
    });
    return groups;
  }

  /// Filters documents based on whether a specified field exists.
  ///
  /// This method filters the documents in the collection based on the presence
  /// or absence of a given [fieldName]. By default, it returns documents that
  /// *contain* the specified field. You can use the optional [exists] parameter
  /// to reverse this behavior and find documents that *do not* contain the field.
  ///
  /// **Parameters:**
  /// - [fieldName]: The name of the field to check for existence.
  /// - [exists]: A boolean value indicating whether to search for documents
  ///   that *contain* the field (`true`) or *do not contain* the field (`false`).
  ///   Defaults to `true`.
  ///
  /// **Returns:**
  /// - A list of maps representing the documents that satisfy the existence
  ///   condition. Returns an empty list if no documents match the criteria.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final documents = {
  ///   "1": {"name": "Alice", "age": 25},
  ///   "2": {"name": "Bob"}, // Missing "age" field
  ///   "3": {"name": "Charlie", "age": 30},
  /// };
  /// final schema = Schema({}); // Dummy schema for the example
  /// final collectionManager = CollectionManager('users', documents, schema);
  ///
  /// // Find users with the "age" field
  /// final withAge = collectionManager.existsQuery("age");
  /// print(withAge);
  ///
  /// // Output:
  ///  [{name: Alice, age: 25}, {name: Charlie, age: 30}]
  ///
  /// // Find users WITHOUT the "age" field
  /// final withoutAge = collectionManager.existsQuery("age", exists: false);
  /// print(withoutAge);
  ///
  /// // Output:
  ///  [{name: Bob}]
  ///
  /// //Find users with the "city" field
  /// final withCity = collectionManager.existsQuery("city");
  /// print(withCity);
  ///
  /// // Output:
  ///  []
  /// ```
  List<Map<String, dynamic>> existsQuery(String fieldName,
      {bool exists = true}) {
    return _documents.entries
        .where((entry) => exists
            ? entry.value.containsKey(fieldName)
            : !entry.value.containsKey(fieldName))
        .map((entry) => entry.value)
        .toList();
  }

  /// Filters documents where a specified field matches a wildcard pattern.
  ///
  /// This method filters documents based on whether the value of the specified
  /// [fieldName] matches a given wildcard [pattern]. The wildcard character `*`
  /// is used to represent zero or more characters. The matching is
  /// case-insensitive.
  ///
  /// **Wildcard Matching:**
  /// The `*` character in the [pattern] is translated to the regular expression
  /// `.*`, which matches any sequence of zero or more characters.
  ///
  /// **Handling Null or Missing Fields:**
  /// If a document does not contain the specified [fieldName] or if the field's
  /// value is `null`, it is treated as an empty string for matching purposes,
  /// meaning it will only match patterns that start with `*` or an empty pattern.
  ///
  /// **Parameters:**
  /// - [fieldName]: The name of the field to check against the wildcard pattern.
  /// - [pattern]: The wildcard pattern to match. Use `*` to represent zero or
  ///   more characters.
  ///
  /// **Returns:**
  /// - A list of maps representing the documents where the specified field's
  ///   value matches the wildcard pattern. Returns an empty list if no documents
  ///   match.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final documents = {
  ///   "1": {"name": "Alice Wonderland"},
  ///   "2": {"name": "Bob the Builder"},
  ///   "3": {"name": "Charlie Chaplin"},
  ///   "4": {"name": "David"},
  ///   "5": {"name": null},
  /// };
  /// final schema = Schema({}); // Dummy schema for the example
  /// final collectionManager = CollectionManager('users', documents, schema);
  ///
  /// // Find names starting with "A"
  /// final startsWithA = collectionManager.wildcardQuery("name", "A*");
  /// print(startsWithA);
  ///
  /// // Output:
  ///  [{name: Alice Wonderland}]
  ///
  /// // Find names ending with "er"
  /// final endsWithEr = collectionManager.wildcardQuery("name", "*er");
  /// print(endsWithEr);
  ///
  /// // Output:
  ///  [{name: Bob the Builder}]
  ///
  /// // Find names containing "li"
  /// final containsLi = collectionManager.wildcardQuery("name", "*li*");
  /// print(containsLi);
  ///
  /// // Output:
  ///  [{name: Alice Wonderland}, {name: Charlie Chaplin}]
  ///
  /// // Find all names
  /// final allNames = collectionManager.wildcardQuery("name", "*");
  /// print(allNames);
  ///
  /// // Output:
  ///  [
  ///   {name: Alice Wonderland},
  ///   {name: Bob the Builder},
  ///   {name: Charlie Chaplin},
  ///   {name: David},
  ///   {name: null}
  /// ]
  ///
  /// // Find name that is null
  /// final nullName = collectionManager.wildcardQuery("name", "");
  /// print(nullName);
  ///
  /// // Output:
  ///  [{name: null}]
  /// ```
  List<Map<String, dynamic>> wildcardQuery(String fieldName, String pattern) {
    final regex = RegExp(pattern.replaceAll('*', '.*'), caseSensitive: false);
    return _documents.entries
        .where(
            (entry) => regex.hasMatch(entry.value[fieldName]?.toString() ?? ''))
        .map((entry) => entry.value)
        .toList();
  }

  /// Queries documents based on the value within a nested field path.
  ///
  /// This method allows you to query documents based on values located deep
  /// within nested objects. The [nestedPath] parameter specifies the path to
  /// the nested field using dot notation (e.g., "address.street.name"). The
  /// method compares the value at the end of this path with the provided
  /// [value].
  ///
  /// **Handling Missing or Non-Map Intermediate Objects:**
  /// If any intermediate object in the [nestedPath] is not a `Map<String, dynamic>`
  /// or if the final field is missing, the document is considered *not* to match
  /// the query. This prevents errors when trying to access non-existent fields.
  ///
  /// **Parameters:**
  /// - [nestedPath]: The dot-separated path to the nested field (e.g.,
  ///   "address.street.name").
  /// - [value]: The value to compare with the value at the end of the
  ///   [nestedPath].
  ///
  /// **Returns:**
  /// - A list of maps representing the documents where the nested field's
  ///   value matches the provided [value]. Returns an empty list if no documents
  ///   match.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final documents = {
  ///   "1": {
  ///     "address": {
  ///       "street": {"name": "Main St", "number": 123},
  ///       "city": "New York"
  ///     }
  ///   },
  ///   "2": {
  ///     "address": {
  ///       "street": {"name": "Oak Ave", "number": 456},
  ///       "city": "Los Angeles"
  ///     }
  ///   },
  ///   "3": {"address": {"city": "Chicago"}}, // Missing "street"
  ///   "4": {"name": "David"}, // Missing "address"
  /// };
  /// final schema = Schema({}); // Dummy schema for the example
  /// final collectionManager = CollectionManager('places', documents, schema);
  ///
  /// // Find places on "Main St"
  /// final mainStreetPlaces =
  ///     collectionManager.nestedFieldQuery("address.street.name", "Main St");
  /// print(mainStreetPlaces);
  ///
  /// // Output:
  ///  [{address: {street: {name: Main St, number: 123}, city: New York}}]
  ///
  /// // Find places with street number 456
  /// final number456Places =
  ///     collectionManager.nestedFieldQuery("address.street.number", 456);
  /// print(number456Places);
  ///
  /// // Output:
  ///  [{address: {street: {name: Oak Ave, number: 456}, city: Los Angeles}}]
  ///
  /// // Find places with name David
  /// final davidPlaces =
  ///     collectionManager.nestedFieldQuery("name", "David");
  /// print(davidPlaces);
  ///
  /// // Output:
  ///  [{name: David}]
  /// ```
  List<Map<String, dynamic>> nestedFieldQuery(
    String nestedPath,
    dynamic value,
  ) {
    return _documents.entries
        .where((entry) {
          final keys = nestedPath.split('.');
          dynamic fieldValue = entry.value;
          for (final key in keys) {
            if (fieldValue is Map<String, dynamic>) {
              fieldValue = fieldValue[key];
            } else {
              return false;
            }
          }
          return fieldValue == value;
        })
        .map((entry) => entry.value)
        .toList();
  }

  /// Creates projections of documents by selecting specific fields.
  ///
  /// This method allows you to retrieve only a subset of fields from each
  /// document in the collection. This can be useful for improving performance
  /// and reducing the amount of data transferred, especially when you only need
  /// specific information from the documents.
  ///
  /// **Parameters:**
  /// - [fields]: A required list of strings representing the field names to
  ///   include in the projections.
  ///
  /// **Returns:**
  /// - A list of maps where each map represents a projection of a document,
  ///   containing only the specified fields. If a document is missing any of the
  ///   requested fields, the corresponding key-value pair will be omitted from
  ///   the projection.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final documents = {
  ///   "1": {"name": "Alice", "age": 25, "city": "New York"},
  ///   "2": {"name": "Bob", "occupation": "Software Engineer"},
  ///   "3": {"name": "Charlie", "age": 30}, // Missing "city" field
  /// };
  /// final schema = Schema({}); // Dummy schema for the example
  /// final collectionManager = CollectionManager('users', documents, schema);
  ///
  /// // Project documents with only "name" and "age" fields
  /// final nameAgeProjections = collectionManager.project(fields: ["name", "age"]);
  /// print(nameAgeProjections);
  /// // Output:
  ///  [
  ///    {"id": "1", "name": "Alice", "age": 25},
  ///    {"id": "2", "name": "Bob"}, // Missing "age" field
  ///    {"id": "3", "name": "Charlie", "age": 30},
  ///  ]
  ///
  /// // Project documents with only "name" field
  /// final nameProjections = collectionManager.project(fields: ["name"]);
  /// print(nameProjections);
  /// // Output:
  ///  [
  ///    {"id": "1", "name": "Alice"},
  ///    {"id": "2", "name": "Bob"},
  ///    {"id": "3", "name": "Charlie"},
  ///  ]
  /// ```
  List<Map<String, dynamic>> project({
    required List<String> fields,
  }) {
    return _documents.entries.map((entry) {
      final doc = {"id": entry.key, ...entry.value};
      return {
        for (var field in fields)
          if (doc.containsKey(field)) field: doc[field]
      };
    }).toList();
  }

  /// Performs aggregate operations on a specified numerical field.
  ///
  /// This method calculates various aggregate values (sum, average, min, max,
  /// count, median, mode, range, variance, and standard deviation) for a given
  /// numerical field across all documents in the collection. It filters out
  /// non-numerical values before performing the calculations.
  ///
  /// **Handling of Empty or Non-Numerical Data:**
  /// - If the collection is empty or if no numerical values are found for the
  ///   specified field, most operations (min, max, median, mode, range,
  ///   variance, stddev) will return `null`.
  /// - The `average` operation will return `0` if there are no numerical values.
  /// - The `count` operation will return `0` if there are no numerical values.
  ///
  /// **Parameters:**
  /// - [fieldName]: The name of the numerical field to perform the
  ///   aggregations on.
  /// - [operations]: A list of [AggregateOperation] enum values specifying the
  ///   aggregate operations to perform.
  ///
  /// **Returns:**
  /// - A `Map<AggregateOperation, dynamic>` where the keys are the requested
  ///   [AggregateOperation] enum values and the values are the corresponding
  ///   calculated aggregate results. If no numerical values are found or the
  ///   collection is empty, appropriate null or zero values are returned as
  ///   described above.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// enum AggregateOperation { sum, average, min, max, count, median, mode, range, variance, stddev }
  /// final documents = {
  ///   "1": {"value": 10},
  ///   "2": {"value": 20},
  ///   "3": {"value": 30},
  ///   "4": {"value": 20},
  ///   "5": {"value": "not a number"}, // Non-numerical value
  /// };
  /// final schema = Schema({}); // Dummy schema for the example
  /// final collectionManager = CollectionManager('data', documents, schema);
  ///
  /// final results = collectionManager.aggregate(
  ///   fieldName: "value",
  ///   operations: [
  ///     AggregateOperation.sum,
  ///     AggregateOperation.average,
  ///     AggregateOperation.min,
  ///     AggregateOperation.max,
  ///     AggregateOperation.count,
  ///     AggregateOperation.median,
  ///     AggregateOperation.mode,
  ///     AggregateOperation.range,
  ///     AggregateOperation.variance,
  ///     AggregateOperation.stddev,
  ///   ],
  /// );
  /// print(results);
  /// // Expected Output (order may vary):
  ///  {
  ///    AggregateOperation.sum: 80,
  ///    AggregateOperation.average: 20.0,
  ///    AggregateOperation.min: 10,
  ///    AggregateOperation.max: 30,
  ///    AggregateOperation.count: 4,
  ///    AggregateOperation.median: 20.0,
  ///    AggregateOperation.mode: [20],
  ///    AggregateOperation.range: 20,
  ///    AggregateOperation.variance: 50.0,
  ///    AggregateOperation.stddev: 7.0710678118654755
  ///  }
  ///
  /// final emptyResults = collectionManager.aggregate(
  ///   fieldName: "value",
  ///   operations: [AggregateOperation.sum],
  /// );
  /// print(emptyResults); // Example with empty data
  /// // Expected output
  /// {AggregateOperation.sum: null}
  ///
  /// final noNumResults = collectionManager.aggregate(
  ///   fieldName: "name",
  ///   operations: [AggregateOperation.sum],
  /// );
  /// print(noNumResults); // Example with no num data
  /// // Expected output
  /// {AggregateOperation.sum: null}
  /// ```
  Map<AggregateOperation, dynamic> aggregate({
    required String fieldName,
    required List<AggregateOperation> operations,
  }) {
    final values = _documents.values
        .map((doc) => doc[fieldName])
        .whereType<num>()
        .toList();
    final results = <AggregateOperation, dynamic>{};

    for (var operation in operations) {
      switch (operation) {
        case AggregateOperation.sum:
          results[operation] =
              values.isNotEmpty ? values.reduce((a, b) => a + b) : null;
          break;
        case AggregateOperation.average:
          results[operation] = values.isNotEmpty
              ? values.reduce((a, b) => a + b) / values.length
              : 0;
          break;
        case AggregateOperation.min:
          results[operation] =
              values.isNotEmpty ? values.reduce((a, b) => a < b ? a : b) : null;
          break;
        case AggregateOperation.max:
          results[operation] =
              values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : null;
          break;
        case AggregateOperation.count:
          results[operation] = values.length;
          break;
        case AggregateOperation.median:
          if (values.isNotEmpty) {
            values.sort();
            final mid = values.length ~/ 2;
            results[operation] = values.length.isOdd
                ? values[mid]
                : (values[mid - 1] + values[mid]) / 2;
          } else {
            results[operation] = null;
          }
          break;
        case AggregateOperation.mode:
          if (values.isNotEmpty) {
            final frequency = <num, int>{};
            for (var value in values) {
              frequency[value] = (frequency[value] ?? 0) + 1;
            }
            final maxFrequency =
                frequency.values.reduce((a, b) => a > b ? a : b);
            results[operation] = frequency.entries
                .where((entry) => entry.value == maxFrequency)
                .map((entry) => entry.key)
                .toList();
          } else {
            results[operation] = null;
          }
          break;
        case AggregateOperation.range:
          if (values.isNotEmpty) {
            final min = values.reduce((a, b) => a < b ? a : b);
            final max = values.reduce((a, b) => a > b ? a : b);
            results[operation] = max - min;
          } else {
            results[operation] = null;
          }
          break;
        case AggregateOperation.variance:
          if (values.length >= 2) {
            final mean = values.reduce((a, b) => a + b) / values.length;
            results[operation] = values
                    .map((value) => (value - mean) * (value - mean))
                    .reduce((a, b) => a + b) /
                values.length;
          } else {
            results[operation] = null;
          }
          break;
        case AggregateOperation.stddev:
          if (values.length >= 2) {
            final variance = values
                    .map((value) =>
                        (value -
                            values.reduce((a, b) => a + b) / values.length) *
                        (value -
                            values.reduce((a, b) => a + b) / values.length))
                    .reduce((a, b) => a + b) /
                values.length;
            results[operation] = math.sqrt(variance);
          } else {
            results[operation] = null;
          }
          break;
      }
    }

    return results;
  }

  /// Filters the documents based on the provided criteria.
  ///
  /// This method allows filtering documents by a specific field and value,
  /// or by a custom condition. It can also include the document ID in the
  /// results if specified.
  ///
  /// - Parameters:
  ///   - fieldName: The name of the field to filter by. If `null`, no field-based filtering is applied.
  ///   - value: The value to filter by. If `null`, no field-based filtering is applied.
  ///   - condition: A custom condition function that takes a document (as a `Map<String, dynamic>`)
  ///     and returns a `bool` indicating whether the document should be included. If `null`, no custom condition is applied.
  ///   - includeId: A `bool` indicating whether to include the document ID in the results. Defaults to `false`.
  ///
  /// - Returns: A `List<Map<String, dynamic>>` containing the filtered documents.
  ///
  /// - Example:
  /// ```dart
  /// final manager = CollectionManager();
  ///
  /// // Filter by field name and value
  /// final filteredByField = manager.filter(fieldName: 'name', value: 'John');
  ///
  /// // Filter by custom condition
  /// final filteredByCondition = manager.filter(condition: (doc) => doc['age'] > 30);
  ///
  /// // Filter and include document ID
  /// final filteredWithId = manager.filter(includeId: true);
  /// ```
  List<Map<String, dynamic>> filter({
    String? fieldName,
    dynamic value,
    bool Function(Map<String, dynamic> doc)? condition,
    bool includeId = false,
  }) {
    return _documents.entries.where((entry) {
      // If a fieldName and value are provided, filter by equality.
      if (fieldName != null && value != null) {
        return entry.value[fieldName] == value;
      }

      // If a custom condition is provided, use it.
      if (condition != null) {
        final doc = {"id": entry.key, ...entry.value};
        return condition(doc);
      }

      // If neither fieldName nor condition is provided, include all documents.
      return true;
    }).map((entry) {
      final doc = {"id": entry.key, ...entry.value};
      return includeId ? doc : entry.value;
    }).toList();
  }
}
