library;

export 'src/collections/collection_manager.dart';
export 'src/collections/schema.dart';

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:nest_db/src/collections/collection_manager.dart';
import 'package:nest_db/src/collections/schema.dart';
import 'package:nest_db/src/db/reactive_engine.dart';
import 'package:nest_db/src/encryption/encryption_handler.dart';

class Nest {
  /// `Nest` is an in-memory database with persistent storage capabilities,
  /// powered by Nest DB. It allows developers to manage collections of
  /// documents, enforce schemas for data validation, and handle encrypted
  /// storage for secure data handling. Additionally, it supports reactive
  /// updates for real-time collection changes.
  ///
  /// ## Features
  ///
  /// - Create and manage collections with schema validation.
  /// - Persistent storage of collections to disk using Nest DB.
  /// - Encrypted storage for secure data handling (optional).
  /// - Reactive engine for watching collection changes in real-time.
  /// - Easy-to-use and lightweight for local database needs.
  ///
  /// ## Getting Started
  ///
  /// Import the package and initialize the database with an encryption key
  /// (optional, but recommended for sensitive data):
  ///
  /// ```dart
  /// import 'package:nest_demo/nest.dart';
  ///
  /// final db = Nest();
  ///
  /// void main() async {
  ///   await db.initialize('your-encryption-key'); // Optional for encryption
  ///   await db.createCollection('users', Schema({
  ///     'id': FieldType(type: String, isRequired: true),
  ///     'name': FieldType(type: String),
  ///     'age': FieldType(type: int),
  ///   }));
  /// }
  /// ```
  ///
  /// Once initialized, you can create collections, perform CRUD operations,
  /// and save data to disk.

  factory Nest() => _instance;

  Nest._internal();

  static final Nest _instance = Nest._internal();

  final Map<String, CollectionManager> _collections = {};
  EncryptionHandler? _encryptionHandler;
  final ReactiveEngine _reactiveEngine = ReactiveEngine();
  String _storagePath = '';

  /// Initializes the Nest DB instance with an optional encryption key.
  ///
  /// The encryption key ensures that all data stored on disk is encrypted
  /// for security purposes. If no encryption key is provided, data will
  /// be stored in plain text.
  ///
  /// Example:
  /// ```dart
  /// await db.initialize('your-encryption-key');
  /// ```
  /// OR
  ///
  /// ```dart
  /// await db.initialize(''); // just provide an empty string if encryption key is not required
  /// ```
  Future<void> initialize(String encryptionKey) async {
    if (_encryptionHandler != null) {
      log("EncryptionHandler is already initialized.");
      return;
    }

    try {
      _encryptionHandler = EncryptionHandler(encryptionKey);
      await _initializeStorage();
      log("DB initialized successfully.");
    } catch (e, stackTrace) {
      log("Error initializing database: $e", error: e, stackTrace: stackTrace);
    }
  }

  /// Creates a new collection with a specified schema in Nest DB.
  ///
  /// Collections allow you to organize and store related documents with
  /// optional schema validation to ensure data integrity.
  ///
  /// Example:
  /// ```dart
  /// await db.createCollection('products', Schema({
  ///   'id': FieldType(type: String, isRequired: true),
  ///   'name': FieldType(type: String),
  ///   'price': FieldType(type: double),
  /// }));
  /// ```
  Future<void> createCollection(String name, Schema schema) async {
    if (_collections.containsKey(name)) {
      log("Collection '$name' already exists.");
      return;
    }

    try {
      _collections[name] = CollectionManager(name, {}, schema);
      await saveCollectionToDisk(name);
      log("Collection '$name' created.");
    } catch (e, stackTrace) {
      log("Error creating collection '$name': $e",
          error: e, stackTrace: stackTrace);
    }
  }

  /// Checks if a collection exists on disk within Nest DB's storage.
  ///
  /// Example:
  /// ```dart
  /// final exists = await db.collectionExists('users');
  /// print('Collection exists: $exists');
  /// ```
  Future<bool> collectionExists(String name) async {
    final filePath = _buildFilePath(name);
    return File(filePath).existsSync();
  }

  /// Retrieves a collection by name from Nest DB.
  ///
  /// Example:
  /// ```dart
  /// final usersCollection = db.getCollection('users');
  /// ```
  CollectionManager? getCollection(String name) => _collections[name];

  /// Watches changes in a specific collection within Nest DB.
  ///
  /// Returns a stream of changes that can be listened to for real-time updates.
  ///
  /// Example:
  /// ```dart
  /// db.watchCollection('users').listen((change) {
  ///   print('Collection changed: $change');
  /// });
  /// ```
  Stream<Map<String, dynamic>> watchCollection(String name) {
    return _reactiveEngine.watch(name);
  }

  /// Saves a specific collection to disk within Nest DB's storage.
  ///
  /// This ensures that the collection's data is persisted for future use.
  ///
  /// Example:
  /// ```dart
  /// await db.saveCollectionToDisk('users');
  /// ```
  Future<void> saveCollectionToDisk(String name) async {
    final collection = _collections[name];
    if (collection == null) {
      log("Cannot save: Collection '$name' does not exist.");
      return;
    }

    final file = File(_buildFilePath(name));
    try {
      final encryptedData =
          _encryptionHandler?.encrypt(jsonEncode(collection.toMap()));
      if (encryptedData != null) {
        await file.writeAsString(encryptedData);
      }
    } catch (e, stackTrace) {
      log("Error saving collection '$name': $e",
          error: e, stackTrace: stackTrace);
    }
  }

  /// Saves all collections managed by Nest DB to disk.
  ///
  /// This method persists the data of all loaded collections to disk.
  ///
  /// Example:
  /// ```dart
  /// await db.saveAllCollections();
  /// ```
  Future<void> saveAllCollections() async {
    for (final name in _collections.keys) {
      await saveCollectionToDisk(name);
    }
  }

  /// Notifies listeners about changes in a collection within Nest DB.
  ///
  /// This method is used internally to trigger reactive updates.
  ///
  /// Example:
  /// ```dart
  /// db.notifyReactive('users', {'id': '1', 'name': 'John Doe'});
  /// ```
  void notifyReactive(String collectionName, Map<String, dynamic> change) {
    _reactiveEngine.notify(collectionName, change);
  }

  /// Initializes Nest DB's internal storage.
  ///
  /// This method performs the following steps:
  /// 1. Retrieves the application documents directory using `getApplicationDocumentsDirectory`.
  /// 2. Sets the `_storagePath` property with the directory path.
  /// 3. Creates a `Directory` object for the storage path if it doesn't exist.
  /// 4. Calls the `_loadCollectionsFromDisk` method to load existing collections from disk.
  ///
  /// Catches any exceptions that occur during initialization and logs them using the `log` function.
  Future<void> _initializeStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _storagePath = directory.path;

      final dir = Directory(_storagePath);
      if (!dir.existsSync()) {
        dir.createSync();
      }

      await _loadCollectionsFromDisk();
    } catch (e, stackTrace) {
      log("Error initializing storage: $e", error: e, stackTrace: stackTrace);
    }
  }

  /// Builds the file path for a collection within Nest DB's storage.
  ///
  /// This method constructs the complete file path for a collection by combining the
  /// `_storagePath` and the collection name with a `.json` extension.
  ///
  /// Parameters:
  ///   - [name]: The name of the collection.
  ///
  /// Returns:
  ///   The complete file path for the collection.
  String _buildFilePath(String name) => '$_storagePath/$name.json';

  /// Loads all collections from disk into Nest DB's memory.
  ///
  /// This method performs the following tasks:
  /// 1. Opens the directory specified by `_storagePath`.
  /// 2. Filters the directory listing to include only files (`whereType<File>()`).
  /// 3. Iterates through each file in the directory:
  ///   - Extracts the collection name from the file path.
  ///   - Reads the file content as a string.
  ///   - Skips empty files.
  ///   - Attempts to decrypt the content using the `_encryptionHandler` (if available).
  ///   - Skips files with invalid or empty decrypted content.
  ///   - Decodes the decrypted content using `jsonDecode`.
  ///   - Validates the decoded data as a `Map<String, dynamic>`.
  ///   - Creates a `Map<String, Map<String, dynamic>>` by converting the values to maps.
  ///   - Creates a new `CollectionManager` instance for the collection with the loaded data and an empty schema.
  ///   - Adds the `CollectionManager` to the `_collections` map with the collection name as the key.
  /// 4. Logs a message for any files containing invalid data.
  /// 5. Logs an error message for any exceptions encountered during file processing.
  ///
  /// This method essentially scans the storage directory, attempts to decrypt and parse collection data from files, and populates the internal `_collections` map with loaded collections.
  Future<void> _loadCollectionsFromDisk() async {
    final dir = Directory(_storagePath);
    final files = dir.listSync().whereType<File>();

    for (final file in files) {
      final collectionName = file.uri.pathSegments.last.split('.').first;

      try {
        final encryptedContent = await file.readAsString();
        if (encryptedContent.isEmpty) continue;

        final decryptedContent = _encryptionHandler?.decrypt(encryptedContent);
        if (decryptedContent == null || decryptedContent.isEmpty) continue;

        final rawData = jsonDecode(decryptedContent);
        if (rawData is Map<String, dynamic>) {
          final data = rawData.map<String, Map<String, dynamic>>((key, value) {
            return MapEntry(key, Map<String, dynamic>.from(value));
          });

          _collections[collectionName] =
              CollectionManager(collectionName, data, Schema({}));
        } else {
          log("Skipping invalid content in '$collectionName.json'.");
        }
      } catch (e, stackTrace) {
        log("Error loading collection '$collectionName': $e",
            error: e, stackTrace: stackTrace);
      }
    }
  }
}
