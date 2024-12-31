import 'dart:developer';

import 'package:nest_db/nest_db.dart';
import 'package:nest_db/src/collections/collection_manager.dart';
import 'package:nest_db/src/collections/schema.dart';
import 'user_model.dart';

class NestService {
  final _userSchema = Schema({
    'id': FieldType(type: String, isRequired: true),
    'name': FieldType(type: String, isRequired: true),
    'age': FieldType(type: int, isRequired: false),
  });

  final Nest _nest = Nest();

  Future<void> initializeDatabase(String encryptionKey) async {
    try {
      await _nest.initialize(encryptionKey);
    } catch (e, stackTrace) {
      log('Error initializing database: $e', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> addUser(UserModel user) async {
    CollectionManager? userCollection;
    bool exists = await _nest.collectionExists("users");

    if (!exists) {
      _nest.createCollection("users", _userSchema);
    }
    // userCollection?.filter(condition: (doc) => doc['age'] > 25 && doc['active']);

    //userCollection?.project();

    userCollection = _nest.getCollection("users");

    Map<String, dynamic> userMap = user.toMap();

    if (userCollection != null) {
      try {
        _userSchema.validate(user.toMap());
        await userCollection.write(user.id ?? '', userMap);
        log('');
      } catch (e) {
        log('Error adding user: $e');
      }
    } else {
      log('No `users` collection found !');
    }
  }

  Future<void> updateUser(String id, UserModel user) async {
    final userCollection = _nest.getCollection("users");
    if (userCollection != null) {
      try {
        final userMap = user.toMap();
        _userSchema.validate(userMap); // Validate before updating
        await userCollection.update(id, userMap);
      } catch (e) {
        log('Error updating user: $e');
      }
    } else {
      log('No `users` collection found !');
    }
  }

  Future<void> deleteUser(String id) async {
    final userCollection = _nest.getCollection("users");
    if (userCollection != null) {
      try {
        await userCollection.delete(id);
      } catch (e) {
        log('Error deleting user: $e');
      }
    } else {
      log('No `users` collection found !');
    }
  }

  Future<UserModel?> readUser(String id) async {
    final userCollection = _nest.getCollection("users");
    if (userCollection != null) {
      try {
        final data = userCollection.read(id);
        if (data != null) {
          try {
            return UserModel.fromMap(data);
          } catch (e) {
            log('Error converting document to UserModel: $e, data: $data');
            return null;
          }
        }
        return null;
      } catch (e) {
        log('Error reading user: $e');
        return null;
      }
    }
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final userCollection = _nest.getCollection("users");
    if (userCollection != null) {
      try {
        List<Map<String, dynamic>> documents =
            userCollection.query((doc) => true);
        return documents
            .map((document) {
              try {
                return UserModel.fromMap(document);
              } catch (e) {
                log('Error converting document to UserModel: $e, data: $document');
                return UserModel();
              }
            })
            .where((user) => user.id != null)
            .toList(); // Filter out null users
      } catch (e) {
        log('Error getting all users: $e');
        return [];
      }
    }
    return [];
  }
}





 // "email": FieldType(
      //   type: String,
      //   validator: (value) {
      //     if (value == null) return;
      //     final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      //     if (!emailRegex.hasMatch(value)) {
      //       throw ArgumentError('Invalid email format for value "$value".');
      //     }
      //   },
      // ),
      // "role": FieldType(
      //   type: String,
      //   enumValues: ["admin", "user", "guest"],
      //   defaultValue: "user",
      // ),