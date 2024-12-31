import 'package:flutter/material.dart';
import 'dart:async'; // Import dart:async for Timer

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
