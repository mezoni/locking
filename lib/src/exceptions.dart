part of locking;

class MutexStateException implements Exception {
  final String message;

  MutexStateException([this.message]);

  String toString() {
    if (message == null) return "$runtimeType";
    return "$runtimeType: $message";
  }
}
