import 'dart:async';

class ReactiveEngine {
  final Map<String, StreamController<Map<String, dynamic>>> _controllers = {};

  Stream<Map<String, dynamic>> watch(String collectionName) {
    _controllers.putIfAbsent(
        collectionName, () => StreamController.broadcast());
    return _controllers[collectionName]!.stream;
  }

  void notify(String collectionName, Map<String, dynamic> change) {
    _controllers[collectionName]?.add(change);
  }
}
