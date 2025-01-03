# Nest DB

<style>
mark {
  background-color: yellow; /* Example: Change to light blue */
}
</style>

<mark>
Beta Version
</mark>

<br>
Nest DB is a lightweight, in-memory database with persistent storage capabilities designed specifically for Flutter applications. It provides a simple yet powerful way to manage structured data within your app, offering features like schema validation, reactive updates, and persistent storage.

## Features

*   **Document-Oriented:** Stores data as collections of JSON-like documents (maps), providing flexibility and ease of use.
*   **Schema Validation:** Enforces data integrity by allowing you to define schemas for your collections, ensuring that documents conform to specific data types and rules.
*   **Reactive Updates:** Integrates with Flutter's reactive framework, allowing you to easily listen for changes in your data and update your UI accordingly.
*   **Persistent Storage:** Saves data to disk, ensuring data persistence across app sessions. Data is stored in individual JSON files for each collection.
*   **Multiple Collections:** Supports managing multiple independent collections within a single Nest database instance.
*   **Encryption (Optional):** Provides optional encryption of stored data for enhanced security.
*   **Simple API:** Offers an intuitive API for performing CRUD (Create, Read, Update, Delete) operations, as well as more advanced queries.

## Getting Started

### 1. Installation:

- Add `nest_db` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  nest_db: <latest version>
```

### 2. Import:

- Import the nest package in your Dart files:

```dart
import 'package:nest_db/nest_db.dart';
```
### 3. Initialization:

Initialize Nest DB before using it, ideally in your main function before running your app:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  final db = Nest();
  await db.initialize('your_encryption_key'); // Optional encryption key
  runApp(MyApp());
}
```

If you don't need encryption, pass an empty string:

```dart
await db.initialize(''); // No encryption
```

### 4. Creating Collections and Defining Schemas:

Create collections and define schemas to enforce data structure. Schemas are optional but highly recommended for data integrity.

```dart
final userSchema = Schema({
  'id': FieldType(type: String, isRequired: true),
  'name': FieldType(type: String),
  'age': FieldType(type: int),
  'email': FieldType(type: String),
  'address': FieldType(type: Map),
});

await db.createCollection('users', userSchema);
```

### 5. Performing CRUD Operations:

Get a CollectionManager instance for a specific collection:

```dart
final usersCollection = db.getCollection('users');
final productsCollection = db.getCollection('products');

if (usersCollection == null || productsCollection == null) {
  // Handle the case where the collection doesn't exist
  return;
}
```

- #### Create (Write):

```dart
await usersCollection.write('1',
{
  id: '1',
  name: 'Alice',
  age: 30,
  email: 'alice@example.com',
  address: {
    street: {
      name: "Main St",
      number: 123
    },
    city: "New York"
  }
});
```

- #### Read:

```dart
final user = await usersCollection.read('1');
print(user?.data); 

// Output: 
{
  id: "1",
  name: "Alice",
  age: 30,
  email: "alice@example.com",
  createdAt: ..., // Actual Date object
  updatedAt: ...  // Actual Date object
}
```

- #### Update:

```dart
await usersCollection.update('1', 
{
  age: 31,
  email: '[email address removed]',
  address: {
    street: {
      name: "Main St",
      number: 124
    },
    city: "New York"
  }
});
```

- #### Delete:

```dart
await usersCollection.delete('your-doc-id');
```

### 6. Advanced Queries:

 * **Project:** Retrieve only specific fields from documents.

  ```dart
   final documents = {
     "1": {"name": "Alice", "age": 25, "city": "New York"},
     "2": {"name": "Bob", "occupation": "Software Engineer"},
     "3": {"name": "Charlie", "age": 30}, // Missing "city" field
   };
   final schema = Schema({}); // Dummy schema for the example
   final collectionManager = CollectionManager('users', documents, schema);
  
   // Project documents with only "name" and "age" fields
   final nameAgeProjections = collectionManager.project(fields: ["name", "age"]);
   print(nameAgeProjections);
   // Output:
    [
      {"id": "1", "name": "Alice", "age": 25},
      {"id": "2", "name": "Bob"}, // Missing "age" field
      {"id": "3", "name": "Charlie", "age": 30},
    ]
  
   // Project documents with only "name" field
   final nameProjections = collectionManager.project(fields: ["name"]);
   print(nameProjections);
   // Output:
    [
      {"id": "1", "name": "Alice"},
      {"id": "2", "name": "Bob"},
      {"id": "3", "name": "Charlie"},
    ]
   ```

* **Exists Query:** Check if a field exists in a document.

 ```dart
   final documents = {
     "1": {"name": "Alice", "age": 25},
     "2": {"name": "Bob"}, // Missing "age" field
     "3": {"name": "Charlie", "age": 30},
   };
   final schema = Schema({}); // Dummy schema for the example
   final collectionManager = CollectionManager('users', documents, schema);
  
   // Find users with the "age" field
   final withAge = collectionManager.existsQuery("age");
   print(withAge);
  
   // Output:
    [{name: Alice, age: 25}, {name: Charlie, age: 30}]
  
   // Find users WITHOUT the "age" field
   final withoutAge = collectionManager.existsQuery("age", exists: false);
   print(withoutAge);
  
   // Output:
    [{name: Bob}]
  
   //Find users with the "city" field
   final withCity = collectionManager.existsQuery("city");
   print(withCity);
  
   // Output:
    []
   ```

* **Wildcard Query:** Search for documents where a field matches a wildcard pattern.

 ```dart
   final documents = {
     "1": {"name": "Alice Wonderland"},
     "2": {"name": "Bob the Builder"},
     "3": {"name": "Charlie Chaplin"},
     "4": {"name": "David"},
     "5": {"name": null},
   };
   final schema = Schema({}); // Dummy schema for the example
   final collectionManager = CollectionManager('users', documents, schema);
  
   // Find names starting with "A"
   final startsWithA = collectionManager.wildcardQuery("name", "A*");
   print(startsWithA);
  
   // Output:
    [{name: Alice Wonderland}]
  
   // Find names ending with "er"
   final endsWithEr = collectionManager.wildcardQuery("name", "*er");
   print(endsWithEr);
  
   // Output:
    [{name: Bob the Builder}]
  
   // Find names containing "li"
   final containsLi = collectionManager.wildcardQuery("name", "*li*");
   print(containsLi);
  
   // Output:
    [{name: Alice Wonderland}, {name: Charlie Chaplin}]
  
   // Find all names
   final allNames = collectionManager.wildcardQuery("name", "*");
   print(allNames);
  
   // Output:
    [
     {name: Alice Wonderland},
     {name: Bob the Builder},
     {name: Charlie Chaplin},
     {name: David},
     {name: null}
   ]
  
   // Find name that is null
   final nullName = collectionManager.wildcardQuery("name", "");
   print(nullName);
  
   // Output:
    [{name: null}]
   ```


* **Nested Field Query:** Query documents based on values within nested objects.

```dart
final documents = {
    "1": {
    "address": {
        "street": {"name": "Main St", "number": 123},
        "city": "New York"
    }
    },
    "2": {
    "address": {
        "street": {"name": "Oak Ave", "number": 456},
        "city": "Los Angeles"
    }
    },
    "3": {"address": {"city": "Chicago"}}, // Missing "street"
    "4": {"name": "David"}, // Missing "address"
};
final schema = Schema({}); // Dummy schema for the example
final collectionManager = CollectionManager('places', documents, schema);

// Find places on "Main St"
final mainStreetPlaces =
    collectionManager.nestedFieldQuery("address.street.name", "Main St");
print(mainStreetPlaces);

// Output:
[{address: {street: {name: Main St, number: 123}, city: New York}}]

// Find places with street number 456
final number456Places =
    collectionManager.nestedFieldQuery("address.street.number", 456);
print(number456Places);

// Output:
[{address: {street: {name: Oak Ave, number: 456}, city: Los Angeles}}]

// Find places with name David
final davidPlaces =
    collectionManager.nestedFieldQuery("name", "David");
print(davidPlaces);

// Output:
[{name: David}]
```

* **7. Reactive Updates:** Listen for changes in a collection

```dart
db.watchCollection('users').listen((change) {
  print('Users collection changed: $change');
});
```
## Contributing
Contributions are welcome! If you find bugs or have feature suggestions, feel free to create an issue or submit a pull request. Make sure to follow the contribution guidelines.

- Report bugs and request features via [GitHub Issues](https://github.com/Atanu-Sabyasachi/nest_db/issues)
- Engage in discussions and help users solve their problems/questions in the [Discussions](https://github.com/discussions)

## License
This package is licensed under the MIT License. See the LICENSE file for more details.

Happy coding! 🎉

This `README.md` covers installation, usage, features, property descriptions, and customization, making it beginner-friendly and informative for all users of the package.

-------------------------------------------------------------

**Version**: 1.0.2  
**Author**: Atanu Sabyasachi Jena  
**License**: MIT
