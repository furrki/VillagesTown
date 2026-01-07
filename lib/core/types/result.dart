import '../errors/failures.dart';

/// A Result type for explicit error handling without exceptions.
/// Either contains a success value of type T, or a failure of type Failure.
sealed class Result<T> {
  const Result._();

  /// Create a successful result.
  const factory Result.success(T value) = Success<T>;

  /// Create a failed result.
  const factory Result.failure(Failure failure) = Failure_<T>;

  /// Check if this is a success.
  bool get isSuccess => this is Success<T>;

  /// Check if this is a failure.
  bool get isFailure => this is Failure_<T>;

  /// Get the success value, or null if this is a failure.
  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Failure_() => null,
      };

  /// Get the failure, or null if this is a success.
  Failure? get failureOrNull => switch (this) {
        Success() => null,
        Failure_(:final failure) => failure,
      };

  /// Get the success value, or throw if this is a failure.
  T get valueOrThrow => switch (this) {
        Success(:final value) => value,
        Failure_(:final failure) => throw failure,
      };

  /// Transform the success value.
  Result<U> map<U>(U Function(T value) transform) => switch (this) {
        Success(:final value) => Result.success(transform(value)),
        Failure_(:final failure) => Result.failure(failure),
      };

  /// Transform the success value with a function that returns a Result.
  Result<U> flatMap<U>(Result<U> Function(T value) transform) => switch (this) {
        Success(:final value) => transform(value),
        Failure_(:final failure) => Result.failure(failure),
      };

  /// Execute a function based on success or failure.
  U fold<U>({
    required U Function(T value) onSuccess,
    required U Function(Failure failure) onFailure,
  }) =>
      switch (this) {
        Success(:final value) => onSuccess(value),
        Failure_(:final failure) => onFailure(failure),
      };

  /// Execute side effect on success.
  Result<T> onSuccess(void Function(T value) action) {
    if (this case Success(:final value)) {
      action(value);
    }
    return this;
  }

  /// Execute side effect on failure.
  Result<T> onFailure(void Function(Failure failure) action) {
    if (this case Failure_(:final failure)) {
      action(failure);
    }
    return this;
  }
}

/// A successful result containing a value.
final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// A failed result containing a failure.
// ignore: camel_case_types
final class Failure_<T> extends Result<T> {
  final Failure failure;

  const Failure_(this.failure) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure_<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Failure($failure)';
}
