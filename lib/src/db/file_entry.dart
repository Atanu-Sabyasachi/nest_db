/// Represents a file entry with metadata.
///
/// Includes `key` (identifier), `createdAt` (immutable creation time),
/// and `updatedAt` (last modification time).
class FileEntry {
  /// A unique identifier for the file.
  final String key;

  /// The timestamp when the file was created. This value is immutable.
  final DateTime createdAt;

  /// The timestamp when the file was last updated. This value changes as needed.
  final DateTime updatedAt;

  /// Constructor for creating a [FileEntry] instance.
  ///
  /// - `createdAt` should be the timestamp of creation.
  /// - `updatedAt` should be the timestamp of the last update (can be equal to `createdAt` initially).
  FileEntry({
    required this.key,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Converts the [FileEntry] instance into a map for storage or serialization.
  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates a [FileEntry] instance from a map.
  ///
  /// Throws a [FormatException] if the map does not contain valid data.
  static FileEntry fromMap(Map<String, dynamic> map) {
    try {
      return FileEntry(
        key: map['key'],
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: DateTime.parse(map['updatedAt']),
      );
    } catch (e) {
      throw FormatException("Invalid data for FileEntry: $e");
    }
  }

  /// Updates the [FileEntry] instance with a new key and updated timestamp.
  ///
  /// The `updatedAt` field is automatically set to the current time.
  FileEntry copyWith({
    String? key,
    DateTime? updatedAt,
  }) {
    return FileEntry(
      key: key ?? this.key,
      createdAt: createdAt, // Retains the original creation time
      updatedAt: updatedAt ?? DateTime.now(), // Updates the modification time
    );
  }

  /// Compares two [FileEntry] instances for equality based on their fields.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileEntry &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  /// Generates a hash code for the [FileEntry] instance.
  @override
  int get hashCode => key.hashCode ^ createdAt.hashCode ^ updatedAt.hashCode;

  /// Provides a readable string representation of the [FileEntry] instance.
  @override
  String toString() {
    return 'FileEntry(key: $key, createdAt: ${createdAt.toIso8601String()}, updatedAt: ${updatedAt.toIso8601String()})';
  }
}

// class FileEntry {
//   final String key;
//   final DateTime createdAt;

//   FileEntry({required this.key, required this.createdAt});

//   Map<String, dynamic> toMap() {
//     return {
//       'key': key,
//       'createdAt': createdAt.toIso8601String(),
//     };
//   }

//   static FileEntry fromMap(Map<String, dynamic> map) {
//     return FileEntry(
//       key: map['key'],
//       createdAt: DateTime.parse(map['createdAt']),
//     );
//   }
// }
