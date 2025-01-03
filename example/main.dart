import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:nest_db/nest_db.dart';
import 'package:nest_db/src/collections/collection_manager.dart';
import 'package:nest_db/src/collections/schema.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const encryptionKey = "my-secretKey-is-my-love-for-food";

  // Initialize database
  await NestService().initializeDatabase(encryptionKey);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int age = 0;
  String id = '', name = '';

  bool _isLoading = true;
  final NestService _nestService = NestService();
  List<UserModel> _userList = [];

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    setState(() => _isLoading = true);
    await _updateUserList();
    setState(() => _isLoading = false);
  }

  Future<void> _addUser(String id, String name, int age) async {
    UserModel user = UserModel(id: id, name: name, age: age);
    await _nestService.addUser(user);
    await _updateUserList();
  }

  Future<void> _updateUserList() async {
    _userList = await _nestService.getAllUsers();
    setState(() {});
  }

  Future<void> _deleteUser(String id) async {
    await _nestService.deleteUser(id);
    await _updateUserList();
  }

  Future<void> _updateUser(String id, String name, int age) async {
    UserModel user = UserModel(id: id, name: name, age: age);
    await _nestService.updateUser(id, user);
    await _updateUserList();
  }

  Future<UserModel?> _readUser(String id) async {
    return await _nestService.readUser(id);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Nest NoSQL Example')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              UserForm(
                onSubmitted: (id, name, age) {
                  setState(() {
                    this.id = id;
                    this.name = name;
                    this.age = age;
                  });
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _addUser(id, name, age);
                    },
                    child: const Text('Add'),
                  ),
                  ElevatedButton(
                      onPressed: () {
                        _deleteUser(id);
                      },
                      child: Text("Delete")),
                  ElevatedButton(
                      onPressed: () {
                        _updateUser(id, name, age);
                      },
                      child: Text("Update")),
                  ElevatedButton(
                      onPressed: () async {
                        await _readUser(id);
                      },
                      child: Text("Read")),
                ],
              ),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : UserList(users: _userList),
            ],
          ),
        ),
      ),
    );
  }
}

class UserForm extends StatefulWidget {
  const UserForm({super.key, required this.onSubmitted});

  final Function(String id, String name, int age) onSubmitted;

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _ageController = TextEditingController();
  Timer? _debounce;
  final _idController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _idController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _submitForm() {
    _debounce?.cancel();

    final id = _idController.text;
    final name = _nameController.text;
    final age = int.tryParse(_ageController.text);

    if (id.isNotEmpty && name.isNotEmpty && age != null) {
      widget.onSubmitted(id, name, age);
      _clearFields();
    }
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _submitForm);
  }

  void _clearFields() {
    _idController.clear();
    _nameController.clear();
    _ageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _idController,
          decoration: const InputDecoration(labelText: 'User ID'),
          onChanged: (_) => _onTextChanged(),
        ),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Name'),
          onChanged: (_) => _onTextChanged(),
        ),
        TextField(
          controller: _ageController,
          decoration: const InputDecoration(labelText: 'Age'),
          keyboardType: TextInputType.number,
          onChanged: (_) => _onTextChanged(),
        ),
      ],
    );
  }
}

class UserList extends StatelessWidget {
  const UserList({
    super.key,
    required this.users,
  });

  final List<UserModel> users;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: users.isEmpty
          ? const Center(child: Text('No users available'))
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user.name ?? ''),
                  subtitle: Text("Age: ${user.age}"),
                  trailing: Text("ID: ${user.id}"),
                );
              },
            ),
    );
  }
}

class UserModel {
  UserModel({
    this.id,
    this.name,
    this.age,
  });

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      age: map['age']?.toInt(),
    );
  }

  int? age;
  String? id;
  String? name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.age == age;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ age.hashCode;

  @override
  String toString() => 'UserModel(id: $id, name: $name, age: $age)';

  UserModel copyWith({
    String? id,
    String? name,
    int? age,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
    };
  }

  String toJson() => json.encode(toMap());
}

class NestService {
  final Nest _nest = Nest();
  final _userSchema = Schema({
    'id': FieldType(type: String, isRequired: true),
    'name': FieldType(type: String, isRequired: true),
    'age': FieldType(type: int, isRequired: false),
  });

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
