import 'package:flutter/material.dart';
import 'user_model.dart';

class UserList extends StatelessWidget {
  final List<UserModel> users;

  const UserList({
    super.key,
    required this.users,
  });

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
