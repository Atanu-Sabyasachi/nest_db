import 'package:flutter/material.dart';
import 'home.dart';
import 'user_list.dart';
import 'nest_service.dart';
import 'user_model.dart';

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
  bool _isLoading = true;
  final NestService _nestService = NestService();
  List<UserModel> _userList = [];
  String id = '', name = '';
  int age = 0;

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
