import 'package:uuid/uuid.dart';

/// Base class for all typed entity IDs.
/// Provides compile-time type safety preventing ID mismatches.
abstract class EntityId {
  final String value;

  const EntityId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$runtimeType($value)';

  /// Generate a new UUID-based ID. Override in subclasses.
  static String generateUuid() => const Uuid().v4();
}
